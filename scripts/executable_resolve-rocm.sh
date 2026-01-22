#!/usr/bin/env bash
set -euo pipefail

shim_dir="${HOME}/.local/share/resolve-rocm-shim"
shim_src="${shim_dir}/resolve-prraw-shim.c"
shim_lib="${shim_dir}/libprraw_shim.so"

mkdir -p "${shim_dir}"

if [[ ! -f "${shim_src}" ]]; then
  cp "${HOME}/scripts/resolve-prraw-shim.c" "${shim_src}"
fi

cc -shared -fPIC -o "${shim_lib}" "${shim_src}"

export OCL_ICD_VENDORS=/etc/OpenCL/vendors/amdocl64.icd
export LD_PRELOAD="${shim_lib}:/usr/lib/libstdc++.so.6"

exec /opt/resolve/bin/resolve "$@"
