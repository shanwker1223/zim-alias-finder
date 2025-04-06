alias-finder() {
  local cmd="" original_cmd=""
  local exact=true longer=false shorter=true use_best_match=true

  zstyle -t ':zim:plugins:alias-finder' include-exact && exact=true
  zstyle -t ':zim:plugins:alias-finder' include-longer && longer=true
  zstyle -t ':zim:plugins:alias-finder' include-shorter && shorter=true
  zstyle -t ':zim:plugins:alias-finder' use-best-match && use_best_match=true

  for c in "$@"; do
    cmd+="$c "
  done
  original_cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  local alias_color="%F{yellow}"
  local command_color="%F{cyan}"
  local reset_color="%f"

  local chain_regex='(&&|\|\||;|\|)'
  if [[ "$cmd" =~ $chain_regex ]]; then
    _process_chain_mode "$original_cmd" "$cmd" "$use_best_match" "$alias_color" "$command_color" "$reset_color"
  else
    _process_single_command "$original_cmd" "$use_best_match" "$exact" "$longer" "$shorter" "$alias_color" "$command_color" "$reset_color"
  fi
}

_get_exact_alias() {
  local search_cmd="$1"
  local mode="$2"
  local best=""
  while IFS='=' read -r a_name a_cmd; do
    a_cmd=${a_cmd#\'}
    a_cmd=${a_cmd%\'}
    if [[ "$a_cmd" == "$search_cmd" ]]; then
      best=$([[ "$mode" == "name" ]] && echo "$a_name" || echo "$a_cmd")
      break
    fi
  done < <(alias)
  echo "$best"
}

_get_best_alias() {
  local search_cmd="$1"
  local tmp="$search_cmd"
  local best_name="" best_cmd=""
  while [[ -n "$tmp" ]]; do
    best_name="$(_get_exact_alias "$tmp" "name")"
    if [[ -n "$best_name" ]]; then
      best_cmd="$(_get_exact_alias "$tmp" "command")"
      echo "${best_name}:${best_cmd}"
      return
    fi
    [[ "$tmp" != *" "* ]] && break
    tmp="${tmp% *}"
  done
  echo ":"
}

_common_prefix_score() {
  local s1="$1" s2="$2"
  local score=0
  local -a words1 words2
  words1=(${=s1})
  words2=(${=s2})
  for (( i=1; i<=${#words1[@]}; i++ )); do
    (( i <= ${#words2[@]} )) || break
    [[ ${words1[i]} == ${words2[i]} ]] || break
    (( score++ ))
  done
  echo $score
}

_word_count() {
  local str="$1"
  local -a words
  words=(${=str})
  echo ${#words[@]}
}

_process_chain_mode() {
  local original_cmd="$1"
  local full_cmd="$2"
  local use_best_match="$3"
  local alias_color="$4"
  local command_color="$5"
  local reset_color="$6"

  local whole_alias="$(_get_exact_alias "$original_cmd" "name")"
  if [[ -n "$whole_alias" ]]; then
    print -P "${alias_color}\"${whole_alias}\"${reset_color}='${command_color}${full_cmd}${reset_color}'"
  fi

  local -a tokens
  tokens=("${(@f)$(echo "$full_cmd" | sed -E 's/([[:space:]]*(&&|\|\||[|;])[[:space:]]*)/\n\2\n/g')}")
  local chain_alias=""
  local substitution_occurred=false token token_alias best_match_pair best_match_name best_match_cmd diff

  for token in "${tokens[@]}"; do
    token=$(echo "$token" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
    if [[ "$token" == "&&" || "$token" == "||" || "$token" == ";" || "$token" == "|" ]]; then
      chain_alias+=" $token "
    elif [[ -n "$token" ]]; then
      token_alias="$(_get_exact_alias "$token" "name")"
      if [[ -n "$token_alias" ]]; then
        chain_alias+="${token_alias}"
        substitution_occurred=true
      elif [[ $use_best_match == true ]]; then
        best_match_pair="$(_get_best_alias "$token")"
        best_match_name="${best_match_pair%%:*}"
        best_match_cmd="${best_match_pair#*:}"
        if [[ -n "$best_match_name" ]]; then
          if [[ "$token" == "$best_match_cmd"* && "$token" != "$best_match_cmd" ]]; then
            diff="${token#$best_match_cmd}"
            diff=$(echo "$diff" | sed 's/^ *//')
            chain_alias+="${best_match_name} ${diff}"
            substitution_occurred=true
          else
            chain_alias+="$token"
          fi
        else
          chain_alias+="$token"
        fi
      else
        chain_alias+="$token"
      fi
    fi
  done

  if [[ "$substitution_occurred" == true ]]; then
    print -P "${alias_color}\"${chain_alias}\"${reset_color}='${command_color}${full_cmd}${reset_color}'"
  fi
}

_process_single_command() {
  local original_cmd="$1"
  local use_best_match="$2"
  local exact="$3"
  local longer="$4"
  local shorter="$5"
  local alias_color="$6"
  local command_color="$7"
  local reset_color="$8"

  local cmp_original="${original_cmd//\'/}"
  local best_match_name="" best_match_cmd=""
  if [[ $use_best_match == true ]]; then
    local best_match_pair="$(_get_best_alias "$original_cmd")"
    best_match_name="${best_match_pair%%:*}"
    best_match_cmd="${best_match_pair#*:}"
  fi

  local -a exact_matches shorter_matches longer_matches
  local a_name a_cmd score

  while IFS='=' read -r a_name a_cmd; do
    a_cmd=${a_cmd#\'}
    a_cmd=${a_cmd%\'}
    if [[ "$a_cmd" == "$cmp_original" ]]; then
      [[ "$exact" == true ]] && exact_matches+=("${a_name}=$a_cmd")
    elif [[ "$cmp_original" == "$a_cmd"* ]]; then
      if [[ "$shorter" == true ]]; then
        score=$(_word_count "$a_cmd")
        shorter_matches+=("${score}:${a_name}=$a_cmd")
      fi
    elif (( $(_common_prefix_score "$cmp_original" "$a_cmd") >= 2 )); then
      if [[ "$longer" == true ]]; then
        score=$(_common_prefix_score "$cmp_original" "$a_cmd")
        longer_matches+=("${score}:${a_name}=$a_cmd")
      fi
    fi
  done < <(alias)

  if (( ${#longer_matches[@]} )); then
    longer_matches=( "${(@f)$(printf "%s\n" "${longer_matches[@]}" | sort -t: -k1,1nr)}" )
    for (( i=1; i<=${#longer_matches[@]}; i++ )); do
      longer_matches[$i]="${longer_matches[$i]#*:}"
    done
  fi

  if (( ${#shorter_matches[@]} )); then
    shorter_matches=( "${(@f)$(printf "%s\n" "${shorter_matches[@]}" | sort -t: -k1,1nr)}" )
    for (( i=1; i<=${#shorter_matches[@]}; i++ )); do
      shorter_matches[$i]="${shorter_matches[$i]#*:}"
    done
  fi

  local -a final_matches
  final_matches=( "${exact_matches[@]}" )
  if [[ $use_best_match == true && -n "$best_match_name" && "$original_cmd" != "$best_match_cmd" ]]; then
    local diff="${original_cmd#$best_match_cmd}"
    diff=$(echo "$diff" | sed 's/^ *//')
    final_matches+=( "\"${best_match_name} ${diff}\"=$original_cmd" )
  fi
  final_matches+=( "${shorter_matches[@]}" )
  final_matches+=( "${longer_matches[@]}" )
  final_matches=( ${final_matches[@][1,10]} )

  local item alias_name alias_def
  for item in "${final_matches[@]}"; do
    alias_name="${item%%=*}"
    alias_def="${item#*=}"
    alias_name="${alias_name//\"/}"
    alias_name="\"${alias_name}\""
    print -P "${alias_color}${alias_name}${reset_color}='${command_color}${alias_def}${reset_color}'"
  done
}

preexec_alias-finder() {
  if [[ "$1" == alias-finder* ]]; then
    return
  fi
  zstyle -t ':zim:plugins:alias-finder' autoload && alias-finder "$1"
}

autoload -U add-zsh-hook
add-zsh-hook preexec preexec_alias-finder
