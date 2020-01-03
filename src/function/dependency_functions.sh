#!/bin/bash

#  Check Apache is installed and running
checkApache()
{
    printf 'Apache                                                      ' | tee -a $LOGFILE
    if systemctl is-active --quiet apache2; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

#  Check if MySQL is installed and running
checkMysql()
{
    printf 'MySQL                                                       ' | tee -a $LOGFILE
    if systemctl is-active --quiet mysql; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

#  Check if PHP is installed and running the proper version
checkPHP()
{
    printf 'PHP '$minimumPHPReadable'                                                     ' | tee -a $LOGFILE
    if hash php 2>/dev/null; then
        PHPVersion=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1,3)
        # minimumRequiredVersion=71;
        if (($PHPVersion >= $minimumPHPVer)); then
            tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
        else
            tput setaf 1
            echo '[FAIL]' | tee -a $LOGFILE
            PREREQ=false
        fi
    else
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

#  Check if the Apache Rewrite Module is installed
checkApacheRewrite()
{
    if $PREREQ; then
        REWRITE=$(apachectl -M | grep 'rewrite_module' > /dev/null 2>&1)
        printf 'Rewrite Module                                              ' | tee -a $LOGFILE
        if $REWRITE; then
            tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
        else	
            tput setaf 1
            echo '[FAIL]' | tee -a $LOGFILE
            PREREQ=false
        fi
    fi
    tput sgr0
}

# Check if Composer is installed
checkComposer()
{
    printf 'Composer                                                    ' | tee -a $LOGFILE
    composer -v > /dev/null 2>&1
    COMPOSER=$?
    if [[ $COMPOSER -ne 0 ]]; then
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    else
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
    fi
    tput sgr0
}
