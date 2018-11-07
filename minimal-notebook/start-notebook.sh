#!/bin/bash

set -x

set -eo pipefail

JUPYTER_ENABLE_LAB=`echo "$JUPYTER_ENABLE_LAB" | tr '[A-Z]' '[a-z]'`
JUPYTER_ENABLE_LMOD=`echo "$JUPYTER_ENABLE_LMOD" | tr '[A-Z]' '[a-z]'`

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

    if [[ "$JUPYTER_ENABLE_LMOD" =~ ^(true|yes|y|1)$ ]]; then
        jupyter serverextension enable --py jupyterlmod --sys-prefix
        jupyter nbextension enable --py jupyterlmod --sys-prefix

        if [[ -r /cvmfs/soft.computecanada.ca/config/profile/bash.sh ]]; then
            source /cvmfs/soft.computecanada.ca/config/profile/bash.sh
            # echo "sourcing lmod profile"
        fi
    fi

    JUPYTER_PROGRAM_ARGS="$JUPYTER_PROGRAM_ARGS --config=/opt/app-root/etc/jupyter_notebook_config.py"

    exec /opt/app-root/bin/start.sh jupyter notebook $JUPYTER_PROGRAM_ARGS "$@"
fi