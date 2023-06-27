#!/bin/bash

set -e

function showHelpCommands {
    echo ""
    echo "Usage: $(basename $0) [command]"
    echo ""
    echo "    where [command] is one of the following:"
    echo ""
    echo "         backup             Takes a backup"
    echo "         restore            Restore a backup"
    echo ""
    echo "    For more detailed information on each command, use:"
    echo "        $(basename $0) [command] --help"
    echo ""
    echo "Notes:"
    echo "  * This requires rclone to be installed and the remotes to be configured on this system. See the rclone"
    echo "    docs for more info: https://rclone.org/"
    echo ""
    exit 1
}

function showHelpBackup {
    echo ""
    echo "Usage: $(basename $0) backup --local=[local] --remote=[remote] (--incremental) (--dry-run)"
    echo ""
    echo "    where:"
    echo ""
    echo "         --local=[local]    The local path to backup"
    echo "         --remote=[remote]  The remote to backup to, see 'rclone config' or examples below"
    echo ""
    echo "    optional:"
    echo ""
    echo "         --incremental      If specified, the backup is incremental instead of full"
    echo "         --dry-run          If specified, dont copy anything, just test"
    echo "         --verbose          If specified, output is more verbose"
    echo ""
    echo "Examples:"
    echo "    # Take an incremental backup of a local directory to offsite"
    echo "    $(basename $0) backup --local=/path/to/files --remote=your-remote: --incremental --dry-run"
    echo ""
    echo "    # Take an full backup of a local directory to offsite"
    echo "    $(basename $0) backup --local=/path/to/files --remote=your-remote: --dry-run"
    echo ""
    echo "Notes:"
    echo "  * This requires rclone to be installed and the remotes to be configured on this system. See the rclone"
    echo "    docs for more info: https://rclone.org/"
    echo ""
    exit 1
}

function showHelpRestore {
    echo ""
    echo "Usage: $(basename $0) restore --source=[source] --remote=[remote] (--date=[date]) (--incremental) (--incremental-date-start=[date]) (--dry-run)"
    echo ""
    echo "    where:"
    echo ""
    echo "         --local=[local]    The local directory to restore to"
    echo "         --remote=[remote]  The remote to restore from, see 'rclone config' or examples below"
    echo ""
    echo "    optional:"
    echo ""
    echo "         --date                    A date in the format Y-M-d-Hms to restore until, default is to use the latest backup date found"
    echo "         --incremental             Should be specified if the backup being restored was incremental"
    echo "         --incremental-date-start  A date in the format Y-M-d-Hms to restore incremental backups after, default is to restore full history until --date (implies --incremental)"
    echo "         --dry-run                 If specified, dont copy anything, just test"
    echo "         --verbose                 If specified, output is more verbose"
    echo ""
    echo "Examples:"
    echo "    # Restore the latest version of an incremental backup"
    echo "    $(basename $0) restore --remote=your-remote: --local=/path/to/put/restored --incremental --dry-run"
    echo ""
    echo "    # Restore a specific point in time incremental backup"
    echo "    $(basename $0) restore --remote=your-remote: --local=/path/to/put/restored --date=2021-04-21-183015 --incremental --dry-run"
    echo ""
    echo "    # Restore only changes between two dates, incremental backup"
    echo "    $(basename $0) restore --remote=your-remote: --local=/path/to/put/restored --date=2021-04-21-183015 --incremental-date-start=2021-04-22-041735 --dry-run"
    echo ""
    echo "    # Restore the latest version of a full backup"
    echo "    $(basename $0) restore --remote=your-remote: --local=/path/to/put/restored --dry-run"
    echo ""
    echo "Notes:"
    echo "  * This requires rclone to be installed and the remotes to be configured on this system. See the rclone"
    echo "    docs for more info: https://rclone.org/"
    echo ""
    echo "  * When restoring a backup that was taken with --incremental, be sure to specify --incremental on the"
    echo "    restore command too, otherwise only the single incremental backup will be restored, it won't restore"
    echo "    all previous files too"
    echo ""
    exit 1
}

# Set default options
operation=""
incremental=false
local=""
remote=""
date=""
incrementalDateStart=""
dry_run_flag=""
verbose_flag=""
RCLONE_BIN=${RCLONE_BIN:-/usr/bin/rclone}

if [ "$1" == "backup" ]; then
    operation="backup"
elif [ "$1" == "restore" ]; then
    operation="restore"
fi

shift

if [ "$operation" == "backup" ]; then

    while test $# -gt 0; do
            case "$1" in
                    -h|--help)
                            showHelpBackup
                            ;;
                    --incremental*)
                            incremental=true
                            export incremental
                            shift
                            ;;
                    --dry-run*)
                            dry_run_flag="--dry-run"
                            export dry_run_flag
                            shift
                            ;;
                    --local*)
                            local=$(echo $1 | sed -e 's/^[^=]*=//g')
                            export local
                            shift
                            ;;
                    --remote*)
                            remote=$(echo $1 | sed -e 's/^[^=]*=//g')
                            export remote
                            shift
                            ;;
                    --verbose*)
                            verbose_flag=" -vv"
                            export verbose_flag
                            shift
                            ;;
                    *)
                            shift
                            continue
                            ;;
            esac
    done

    if [ "$local" == "" ] || [ "$remote" == "" ]
    then
        echo "Missing arguments"
        showHelpBackup
        exit 1
    fi

    function join_by { local d=${1-} f=${2-}; if shift 2; then printf %s "$f" "${@/#/$d}"; fi; }

    if [ $incremental == true ]
    then
        echo "$(date) Starting incremental backup"

        # Get the latest previous incremental backup
        mapfile -t compareDestFlags < <($RCLONE_BIN lsf --dir-slash=false ${remote}/incremental)

        cnt=${#compareDestFlags[@]}

        echo "$cnt previous backups detected (${compareDestFlags[*]})"

        for ((i=0;i<cnt;i++)); do
            path=${compareDestFlags[i]%/}
            compareDestFlags[i]=" --compare-dest=${remote}/incremental/${path}"
        done

        $RCLONE_BIN copy --no-traverse --immutable --copy-links ${local} ${remote}/incremental/$(date +"%Y-%m-%d-%H%M%S") ${dry_run_flag} ${compareDestFlags[*]} ${verbose_flag}

    else
         echo "$(date) Starting full backup"

        $RCLONE_BIN copy --no-traverse --immutable --copy-links ${local} ${remote}/full/$(date +"%Y-%m-%d-%H%M%S") ${dry_run_flag} ${verbose_flag}
    fi
elif [ "$operation" == "restore" ]; then

     while test $# -gt 0; do
            case "$1" in
                    -h|--help)
                            showHelpRestore
                            ;;
                    --incremental-date-start*)
                            incrementalDateStart=$(echo $1 | sed -e 's/^[^=]*=//g')
                            incremental=true
                            export incrementalDateStart
                            export incremental
                            shift
                            ;;
                    --incremental*)
                            incremental=true
                            export incremental
                            shift
                            ;;
                    --dry-run*)
                            dry_run_flag="--dry-run"
                            export dry_run_flag
                            shift
                            ;;
                    --local*)
                            local=$(echo $1 | sed -e 's/^[^=]*=//g')
                            export local
                            shift
                            ;;
                    --remote*)
                            remote=$(echo $1 | sed -e 's/^[^=]*=//g')
                            export remote
                            shift
                            ;;
                    --date*)
                            date=$(echo $1 | sed -e 's/^[^=]*=//g')
                            export date
                            shift
                            ;;
                    --verbose*)
                            verbose_flag=" -vv"
                            export verbose_flag
                            shift
                            ;;
                    *)
                            shift
                            continue
                            ;;
            esac
    done

    if [ "$local" == "" ] || [ "$remote" == "" ]
    then
      echo "Error: Missing arguments"
      showHelpBackup
      exit 1
    fi

    echo "$(date) Starting!"

    # Ensure the destination doesn't have anything in there, for protection
    if [ ! -z "$(ls -A $local)" ]; then
       echo "$(date) Error: The local directory ${local} exists and has contents in it, cannot restore into a non-empty directory"
       exit 1
    fi

    if [ $incremental == true ]
    then
        echo "Starting restore of incremental backup"

        # Get the previous incremental backups
        mapfile -t prevBackups < <($RCLONE_BIN lsf --dir-slash=false ${remote}/incremental/)

        # Sort the previous backups oldest first
        IFS=$'\n' prevBackups=($(sort <<<"${prevBackups[*]}"))
        unset IFS

        IFS=$'\n' prevBackupsNewestFirst=($(sort -r <<<"${prevBackups[*]}"))
        unset IFS

        if [ "$date" != "" ]; then

            dateFound=false

            datesToRestore=()

            for prevBackup in "${prevBackups[@]}"; do

                if [[ "$date" > "$prevBackup" ]]; then

                    if [[ " $incrementalDateStart " == "  " ]]; then
                        echo "adding $prevBackup because backup is before target date $date (and incrementalDateStart is not set)"
                        datesToRestore+=($prevBackup)
                    fi

                    if [[ "$incrementalDateStart" < "$prevBackup" ]]; then
                        echo "adding $prevBackup because it's after incrementalDateStart: $incrementalDateStart"
                        datesToRestore+=($prevBackup)
                    fi

                    if [[ "$incrementalDateStart" == "$prevBackup" ]]; then
                        echo "adding $prevBackup because exact match incrementalDateStart: $incrementalDateStart"
                        datesToRestore+=($prevBackup)
                    fi
                fi

                if [ " $date " == " $prevBackup " ]; then
                    echo "adding $prevBackup because exact match date: $date"
                    datesToRestore+=($prevBackup)
                fi
            done

            if [ "${#datesToRestore[@]}" -lt 1 ]; then
                echo "No dates matched in the remote, review your --incremental-date-start and --date arguments and see the remote for \
                dates there"
                echo "The most recent 10 backups listed newest first are (check the remote to see them all):"

                mostRecentBackupDates=("${prevBackupsNewestFirst[@]:0:10}")

                for backupDate in "${mostRecentBackupDates[@]}"; do
                    echo "    $backupDate"
                done

                exit 1
            fi
        fi

        datesToRestore=($(for date in "${datesToRestore[@]}"; do echo "${date}"; done | sort --unique))
        cnt=${#datesToRestore[@]}

        echo "============"
        echo "Summary of versions to restore:"
        for date in "${datesToRestore[@]}"; do
            echo "  $date"
        done

        echo "============"

        # Now loop over all backups and apply them incrementally, starting with the oldest until
        # we reach the desired date
        for index in "${!datesToRestore[@]}"; do

            prevBackup=${datesToRestore[$index]}

            counter=$(( index+1 ))

            percentComplete=$(( index*100/cnt ))

            echo "$(date) processing backup: $prevBackup $counter/$cnt ($percentComplete%)"

            $RCLONE_BIN copy --no-traverse --copy-links ${remote}/incremental/${prevBackup} ${local} ${dry_run_flag} ${verbose_flag}
        done

    else
        echo "Starting restore of full backup"

        mapfile -t prevBackups < <($RCLONE_BIN lsf --dir-slash=false ${remote}/full/)

        # Sort the previous backups newest first
        IFS=$'\n' prevBackups=($(sort -r <<<"${prevBackups[*]}"))
        unset IFS

        if [ "$date" != "" ]; then

            dateFound=false

            for prevBackup in "${prevBackups[@]}"; do
                if [ " $date " == " $prevBackup " ]; then
                    dateFound=true
                    break
                fi
            done

            if [ $dateFound != true ]; then
                echo "Date '$date' not found in the remote, specify a valid backup date or don't specify --date to restore the most recent backup"
                echo "Most recent 10 backups are (check the remote to see them all):"

                mostRecentBackupDates=("${prevBackups[@]:0:10}")

                for backupDate in "${mostRecentBackupDates[@]}"; do
                    echo "    $backupDate"
                done

                exit 1
            fi

            remote="$remote/full/$date"
        else
            remote="$remote/full/${prevBackups[0]}"
        fi

        $RCLONE_BIN copy --no-traverse --immutable --copy-links ${remote} ${local} ${dry_run_flag} ${verbose_flag}
    fi
else
    # Invalid operation
    showHelpCommands
fi

echo "$(date) Done!"

exit 0

