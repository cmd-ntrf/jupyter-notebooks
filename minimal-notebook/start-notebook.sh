#!/bin/bash

set -x

set -eo pipefail

JUPYTER_ENABLE_LAB=`echo "$JUPYTER_ENABLE_LAB" | tr '[A-Z]' '[a-z]'`
JUPYTER_ENABLE_LMOD=`echo "$JUPYTER_ENABLE_LMOD" | tr '[A-Z]' '[a-z]'`

if [[ "$JUPYTER_ENABLE_LMOD" =~ ^(true|yes|y|1)$ ]]; then
    for file in z-000-init.sh z-15-override.sh z-20-lmod.sh; do
        if [[ -r /cvmfs/soft.computecanada.ca/config/profile.d/$file ]]; then
            source /cvmfs/soft.computecanada.ca/config/profile.d/$file
        fi
    done
fi

if [[ ! -z "${JUPYTERHUB_API_TOKEN}" ]]; then
    exec /opt/app-root/bin/start-singleuser.sh "$@"
elif [[ "$JUPYTER_ENABLE_LAB" =~ ^(true|yes|y|1)$ ]]; then
    exec /opt/app-root/bin/start-lab.sh "$@"
else
    if [ x"$JUPYTER_MASTER_FILES" != x"" ]; then
        if [ x"$JUPYTER_WORKSPACE_NAME" != x"" ]; then
            JUPYTER_WORKSPACE_PATH=/opt/app-root/src/$JUPYTER_WORKSPACE_NAME
            setup-volume.sh $JUPYTER_MASTER_FILES $JUPYTER_WORKSPACE_PATH
        fi
    fi

    if [ x"$JUPYTER_WORKSPACE_NAME" != x"" ]; then
        JUPYTER_PROGRAM_ARGS="$JUPYTER_PROGRAM_ARGS --NotebookApp.default_url=/tree/$JUPYTER_WORKSPACE_NAME"
    fi

    if [ x"$JUPYTER_RSTUDIO" != x"" ]; then
        module load rstudio-server
        JUPYTER_PROGRAM_ARGS="$JUPYTER_PROGRAM_ARGS --NotebookApp.default_url=/rstudio"
    fi

    if [[ "$JUPYTER_ENABLE_LMOD" =~ ^(true|yes|y|1)$ ]]; then
        jupyter serverextension enable --py jupyterlmod --sys-prefix
        jupyter nbextension enable --py jupyterlmod --sys-prefix
        # only expected way to provide R and RStudio for now is through CVMFS
        jupyter serverextension enable  --py --sys-prefix nbrsessionproxy
        jupyter nbextension     enable  --py --sys-prefix nbrsessionproxy
    fi

    JUPYTER_PROGRAM_ARGS="$JUPYTER_PROGRAM_ARGS --config=/opt/app-root/etc/jupyter_notebook_config.py"

    exec /opt/app-root/bin/start.sh jupyter notebook $JUPYTER_PROGRAM_ARGS "$@"
fi