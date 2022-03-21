## Introduction

### Background

AOSC OS has a long history of manual installation, like Arch Linux or Gentoo.
However, manual installation is considered unfriendly for new users,
especially when some distributions like Ubuntu have much smoother installation experience.
Therefore, the community decided to create a friendly installer program, under the name "`DeployKit`" or "`aoscdk-rs`".
In the following text, this program may also be referred as  "DK" or "this program".

The source code of DeployKit may be found at:

> [https://github.com/AOSC-Dev/aoscdk-rs](https://github.com/AOSC-Dev/aoscdk-rs)


### Technical Requirements

#### Architecture

DeployKit shall work on the `amd64` architecture.
If possible, it will be nice to have it compatible with other mainline architectures (e.g. `arm64`).

Compatibility with Retro architectures (e.g. `ppc64el`) will be a surprise, and not an expectation.

#### Software Environment

DeployKit shall work in a generic LiveCD environment, inside a generic interactive shell (hopefully `bash`).
DK shall work in a TUI fashion and shall not require any GUI.

#### Choices of Technology

DeployKit shall be developed with the Rust language. It may have minimal runtime dependencies such as:

> glibc, coreutils, ncurses, wget, curl


### Usability Objectives

- The user only needs basic command-line knowledge.
- The user can get links to the documentation when in doubt, hopefully by scanning a QR code.


