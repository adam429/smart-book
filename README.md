# smart-book

## require_remote 

`require_remote` can require github repo library without manually download the code.

URI Format:  @[user]/[repo]/[directory]/[file]

 - user: the Github user name
 - repo: the Github repo name
 - directory: which directory file to require
 - file: which file to require
 - branch: Github branch is `main` by default

For Example:

```require_remote '@adam429/smart-book/examples/require_remote/lib/math_lib'```

The code will require file from https://github.com/adam429/smart-book/blob/main/examples/require_remote/lib/math_lib.rb
