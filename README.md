# LIVR-VUB Singularity Containers

[![GitHub Container Registry](https://img.shields.io/badge/GHCR-livr--vub-blue?logo=github)](https://github.com/orgs/LIVR-VUB/packages)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Pre-built **Singularity/Apptainer containers** for reproducible bioimage analysis on HPC clusters.

> **Quick Start**: `singularity pull oras://ghcr.io/livr-vub/cellprofiler:latest`

---

## Available Containers

| Container | Version | Description | Size | Pull Command |
|-----------|---------|-------------|------|--------------|
| **cellprofiler** | 4.2.x | Cell image analysis | ~1.9 GB | `singularity pull oras://ghcr.io/livr-vub/cellprofiler:latest` |
| **cellprofiler_426** | 4.2.6 | Cell image analysis (pinned) | ~1.5 GB | `singularity pull oras://ghcr.io/livr-vub/cellprofiler_426:latest` |
| **cp2m_quant** | - | Cellpose-SAM + AICISImageIO (No GUI support) | ~10 GB | `singularity pull oras://ghcr.io/livr-vub/cp2m_quant:latest` |
| **svetlana** | - | NN based cell classification | ~8.4 GB | `singularity pull oras://ghcr.io/livr-vub/svetlana:latest` |
| **cellpose4** | - | Cellpose-SAM with GUI support | ~10 GB | `singularity pull oras://ghcr.io/livr-vub/cellpose4:latest` |
| **cellpose_cellprofiler** | - | Cellpose 2 with cellprofiler with GUI support | ~8 GB | `singularity pull oras://ghcr.io/livr-vub/Cellprofiler_cellpose:latest` |

---

## Quick Start

### Download a Container

```bash
# Using Singularity
singularity pull oras://ghcr.io/livr-vub/cellprofiler:latest

# Using Apptainer (Singularity's successor)
apptainer pull oras://ghcr.io/livr-vub/cellprofiler:latest
```

### Run a Container

```bash
# Interactive shell
singularity shell cellprofiler_latest.sif

# Execute a command
singularity exec cellprofiler_latest.sif cellprofiler --help

# Run with GPU (for Cellpose)
singularity exec --nv svetlana_latest.sif python -c "import cellpose"
```

### Use on HPC (SLURM)

```bash
#!/bin/bash
#SBATCH --job-name=cellprofiler
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G

module load Apptainer  # or Singularity

singularity exec cellprofiler_latest.sif \
    cellprofiler -c -r -p pipeline.cppipe -i ./input -o ./output
```

---

## Download Script

Use the automated download script:

```bash
# Download the script
curl -LO https://raw.githubusercontent.com/LIVR-VUB/containers/main/download_containers.sh
chmod +x download_containers.sh

# Run it
./download_containers.sh
```

Or download all containers at once:

```bash
#!/bin/bash
# download_all.sh

CONTAINERS=("cellprofiler" "cellprofiler_426" "cp2m_quant" "svetlana")

for container in "${CONTAINERS[@]}"; do
    echo "Downloading ${container}..."
    singularity pull "oras://ghcr.io/livr-vub/${container}:latest"
done
```

---

## Upload Containers (Maintainers Only)

### Prerequisites

1. **GitHub Personal Access Token (PAT)** with `write:packages` permission
   - Create at: https://github.com/settings/tokens/new
   - Required scopes: `write:packages`, `read:packages`

2. **ORAS CLI** (installed automatically by script, or manually):
   ```bash
   VERSION="1.1.0"
   curl -LO "https://github.com/oras-project/oras/releases/download/v${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
   tar -zxf oras_${VERSION}_linux_amd64.tar.gz
   sudo mv oras /usr/local/bin/
   ```

### Upload a Container

```bash
# 1. Login to GitHub Container Registry
oras login ghcr.io -u YOUR_GITHUB_USERNAME

# 2. Push the container (name MUST be lowercase)
oras push ghcr.io/livr-vub/CONTAINER_NAME:latest \
    --artifact-type application/vnd.sylabs.sif.layer.v1.sif \
    "your_container.sif:application/vnd.sylabs.sif.layer.v1.sif"
```

### Upload Script

Use the automated upload script:

```bash
./upload_to_ghcr.sh
```

> **Important**: Container names in GHCR must be **lowercase**!

---

## Building Containers

### From Definition File

```bash
# Build from .def file
sudo singularity build cellprofiler.sif cellprofiler.def

# Or with Apptainer
apptainer build cellprofiler.sif cellprofiler.def
```

### Example Definition File

```singularity
Bootstrap: docker
From: cellprofiler/cellprofiler:4.2.6

%labels
    Author LIVR-VUB
    Version 4.2.6

%post
    apt-get update && apt-get install -y python3-pip
    pip3 install numpy pandas scikit-image

%runscript
    exec cellprofiler "$@"

%help
    CellProfiler container for HPC image analysis.
    Usage: singularity exec cellprofiler.sif cellprofiler [options]
```

---

## Software Citations

Please cite the original software when using these containers:

### CellProfiler

> Stirling DR, Swain-Bowden MJ, Lucas AM, Carpenter AE, Cimini BA, Goodman A (2021).  
> **CellProfiler 4: improvements in speed, utility and usability.**  
> *BMC Bioinformatics* 22:433.  
> https://doi.org/10.1186/s12859-021-04344-9

```bibtex
@article{stirling2021cellprofiler,
  title={CellProfiler 4: improvements in speed, utility and usability},
  author={Stirling, David R and Swain-Bowden, Madison J and Lucas, Anne M and Carpenter, Anne E and Cimini, Beth A and Goodman, Allen},
  journal={BMC bioinformatics},
  volume={22},
  pages={1--11},
  year={2021},
  publisher={Springer}
}
```

### Cellpose

> Stringer C, Wang T, Michaelos M, Pachitariu M (2021).  
> **Cellpose: a generalist algorithm for cellular segmentation.**  
> *Nature Methods* 18:100-106.  
> https://doi.org/10.1038/s41592-020-01018-x

```bibtex
@article{stringer2021cellpose,
  title={Cellpose: a generalist algorithm for cellular segmentation},
  author={Stringer, Carsen and Wang, Tim and Michaelos, Michalis and Pachitariu, Marius},
  journal={Nature methods},
  volume={18},
  number={1},
  pages={100--106},
  year={2021},
  publisher={Nature Publishing Group}
}
```

---

## License

Container configurations: **MIT License**

The packaged software retains its original licenses:
- CellProfiler: BSD-3-Clause
- Cellpose: BSD-3-Clause

---

## Contributing

1. Fork this repository
2. Create your container definition (`.def` file)
3. Build and test locally
4. Submit a Pull Request

---

## Contact

**LIVR-VUB** - Liver Cell Biology Research Group  
Vrije Universiteit Brussel (VUB)

- GitHub: [@LIVR-VUB](https://github.com/LIVR-VUB)
- Issues: [Open an issue](https://github.com/LIVR-VUB/containers/issues)

---

<p align="center">
  <i>Built with ❤️ for reproducible science</i>
</p>
