# ROCm-Installer
> AMDgpu-dkms / ROCm Installer for Entropy Linux [Debian]

<img src="https://github.com/GNU-Szmelc/ROCm-Installer/assets/95081005/a6da4223-7ed2-423b-bd42-483fb6d1adaa" alt="Image" width="500" />

### Usage
> Run this command in bash to start installer
```bash
curl https://raw.githubusercontent.com/GNU-Szmelc/ROCm-Installer/main/setup.sh > setup.sh
chmod +x setup.sh && ./setup.sh
```

### To-Do
- ~~Adopt it to Entropy's PostInstall Manager~~
- Add platform detection / use appropriate commands for other distros
- Add CUDA Installer and package both into GPU Driver Manager
- Track versions & update main branch when new packages are out
