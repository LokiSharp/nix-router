# ================= NixOS related =========================

export def nixos-switch [
    name: string
    mode: string
] {
    if "debug" == $mode {
        # show details via nix-output-monitor
        nom build $".#nixosConfigurations.($name).config.system.build.toplevel" --show-trace --verbose
        nixos-rebuild switch --use-remote-sudo --flake $".#($name)" --show-trace --verbose
    } else {
        nixos-rebuild switch --use-remote-sudo --flake $".#($name)"
    }
}

# ====================== Misc =============================

export def make-editable [
    path: string
] {
    let tmpdir = (mktemp -d)
    rsync -avz --copy-links $"($path)/" $tmpdir
    rsync -avz --copy-links --chmod=D2755,F744 $"($tmpdir)/" $path
}

# Build and upload a VM image
export def upload-vm [
    name: string
    mode: string
] {
    let target = $".#($name)"
    if "debug" == $mode {
        nom build $target --show-trace --verbose
    } else {
        nix build $target
    }

    let remote = $"root@Server-NixOS:/data/apps/caddy/fileserver/vms/($name).qcow2"
    rsync -avz --progress --copy-links --checksum result/nixos.qcow2 $remote
}
