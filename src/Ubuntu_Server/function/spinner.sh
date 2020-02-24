#!/bin/bash

spin()
{
    spinner="/|\\-/|\\-"
    while:
    do
        for i in `seq 0 7`
        do  
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.5
        done
    done
}