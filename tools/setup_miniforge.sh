#!/usr/bin/env bash
set -euo pipefail

if [ -z "${PS1:-}" ]; then
    PS1=__dummy__
fi


unames="$(uname -s)"
unamem="$(uname -m)"
is_windows=false

if [[ ${unames} =~ Linux ]]; then
    script="Miniforge3-Linux-${unamem}.sh"
elif [[ ${unames} =~ Darwin ]]; then
    script="Miniforge3-MacOSX-${unamem}.sh"
elif [[ ${unames} =~ MINGW || ${unames} =~ CYGWIN || ${unames} =~ MSYS ]]; then
    is_windows=true
    script="Miniforge3-Windows-${unamem}.exe"
else
    echo "Error: not supported platform: ${unames}"
    exit 1
fi


if [ $# -gt 4 ]; then
    echo "Usage: $0 [output] [conda-env-name] [python-version]"
    exit 1;
elif [ $# -eq 3 ]; then
    output_dir="$1"
    name="$2"
    PYTHON_VERSION="$3"
elif [ $# -eq 2 ]; then
    output_dir="$1"
    name="$2"
    PYTHON_VERSION=""
elif [ $# -eq 1 ]; then
    output_dir="$1"
    name=""
    PYTHON_VERSION=""
elif [ $# -eq 0 ]; then
    output_dir=venv
    name=""
    PYTHON_VERSION=""
fi

if [ -e activate_python.sh ]; then
    echo "Warning: activate_python.sh already exists. It will be overwritten"
fi

if [ ! -e "${output_dir}/etc/profile.d/conda.sh" ]; then
    if [ ! -e "${script}" ]; then
        wget --tries=3 --no-check-certificate "https://github.com/conda-forge/miniforge/releases/latest/download/${script}"
    fi
    if "${is_windows}"; then
        echo "Error: miniforge installation is not supported for Windows for now."
        exit 1
        # https://conda.io/projects/conda/en/latest/user-guide/install/windows.html#installing-in-silent-mode
        # shellcheck disable=SC2317
        _output_dir="$(realpath ${output_dir} | tr / \\)"
        # FIXME(kamo): hangup
        # shellcheck disable=SC2317
        ./"${script}" /InstallationType=JustMe /RegisterPython=0 /S /D="${_output_dir}"
    else
        bash "${script}" -b -p "${output_dir}" -u
    fi
fi

# shellcheck disable=SC1090
source "${output_dir}/etc/profile.d/conda.sh"
conda deactivate

# If the env already exists, skip recreation
if [ -n "${name}" ] && ! conda activate ${name}; then
    conda create -yn "${name}"
fi
conda activate ${name}

conda config --prepend channels https://software.repos.intel.com/python/conda/

if [ -n "${PYTHON_VERSION}" ]; then
    conda install -y conda "python=${PYTHON_VERSION}"
else
    conda install -y conda
fi

conda install -y pip setuptools

if [ "${unamem}" = "x86_64" ]; then
    conda install -y mkl=2024.0
fi

cat << EOF > activate_python.sh
#!/usr/bin/env bash
# THIS FILE IS GENERATED BY tools/setup_miniforge.sh
if [ -z "\${PS1:-}" ]; then
    PS1=__dummy__
fi
. $(cd ${output_dir}; pwd)/etc/profile.d/conda.sh && conda deactivate && conda activate ${name}
EOF
