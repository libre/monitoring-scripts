#!/bin/bash
REQNBR=$(postqueue -p | grep -i "Requests." | awk '{print $5}')
if [[ -n $REQNBR ]]; then
        echo $REQNBR
	else
        echo 0
fi
exit