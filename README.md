# NixOS configs

## Build and switch OS config

(Assuming [just](https://github.com/casey/just) is installed/available)


To build the nixos config for host `frametop`:
```
just dobuild frametop
```

To (build if neeeded, and) switch to the nixos config for host `frametop`:
```
sudo just doswitch frametop
```

To buid / switch the current host (the name of the nixos config must match your `` `hostname` ``):
```
just rebuild
sudo just reswitch
```

(just commands prefix `do` & `re` allows for nicer completions)
