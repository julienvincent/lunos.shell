# Personal DE Shell

## LSP

We are aware of the following issues:

- Qmlls does not work well when a file is not correctly structured. This means
  that completions and lints won’t work unless braces are closed correctly and
  such.
- The LSP cannot provide any documentation for Quickshell types.
- PanelWindow in particular cannot be resolved.

## Misc

Many users use root imports, in the form import "root:/path/to/module". These
are an old Quickshell feature that will break the LSP and singletons. Keep that
in mind if you decide to use them.

A replacement without these issues is planned.
