# Alias Finder

A Zim module that automatically finds and suggests useful aliases for your commands. This module listens to your command input and, based on your pre-defined aliases, provides dynamic alias suggestions that can streamline your workflow.

## Features

- **Automatic Alias Suggestions:** Detects when you type a command and suggests a corresponding alias if one exists.
- **Chain Command Handling:** Processes complex command chains (using `&&`, `||`, `;`, or `|`) and suggests aliases for individual segments.
- **Customizable Matching:** Offers configuration options to include exact matches, longer matches, shorter matches, or the best match based on common prefix scoring. *Note: Exact, shorter, and best match are enabled by default.*
- **Search for Aliases:** You can search for aliases by using a command like `alias-finder "git status"`.

## Installation

Add the module to your Zim configuration by adding the following line to your `.zimrc` file:

```sh
zmodule shanwker1223/zim-alias-finder
```

Then run the install command:

```sh
zimfw install
```

## Usage

Once installed, the module hooks into your shell's pre-execution process. It listens to every command and, if a corresponding alias is found or a best-match alias is determined, it prints a suggestion before executing the command.

For example, if you have an alias defined as:

```sh
alias gs='git status'
```

And you type:

```sh
alias-finder "git status"
```

The module may output a suggestion like:

```
"gs"='git status'
```

This reminder helps you quickly remember and utilize your available aliases.

## Customization

The module behavior is fully customizable using Zsh styles. You can set these options in your `.zshrc` or `.zimrc` file.

### Matching Options

- **Include Exact Matches:**  
  Only suggest aliases that exactly match your command. *(Enabled by default)*  
  ```sh
  zstyle -t ':zim:plugins:alias-finder' include-exact yes
  ```

- **Include Longer Matches:**  
  Also include suggestions where the alias command is longer than your typed command. *(Disabled by default)*
  ```sh
  zstyle -t ':zim:plugins:alias-finder' include-longer yes
  ```

- **Include Shorter Matches:**  
  Include suggestions where the alias command is shorter than your command. *(Enabled by default)*  
  ```sh
  zstyle -t ':zim:plugins:alias-finder' include-shorter yes
  ```

- **Use Best Match:**  
  Enable best-match suggestions based on common prefix scoring. *(Enabled by default)*  
  ```sh
  zstyle -t ':zim:plugins:alias-finder' use-best-match yes
  ```

## How It Works

The module defines a primary function `alias-finder` that:

- **Parses Commands:** Combines the input arguments into a full command and trims whitespace.
- **Alias Matching:** Checks the current command against your defined aliases using helper functions to find exact and best matches.
- **Chain vs. Single Command:** Processes chained commands (using `&&`, `||`, `;`, or `|`) separately from single commands.
- **Output Suggestions:** Prints a suggested alias if a match is found.
- **Automatic Hook:** Utilizes a pre-execution hook so that your commands are automatically inspected before execution.

## Credits

This module was inspired by the alias-finder plugin from Oh My Zsh.  
[Oh My Zsh alias-finder](https://github.com/ohmyzsh/ohmyzsh/blob/master/plugins/alias-finder/README.md)

## License

Distributed under the [MIT License](LICENSE).
