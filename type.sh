#!/bin/bash
#
# 2018/02/11
# Mamoru Kaminaga
# Copyright 2019 Mamoru Kaminaga
# Script for touch type practice.
#
# This software is released under the MIT License.
# http://opensource.org/licenses/mit-license.php
#
# 2018/02/11
#  * first scratch.
#
# 2019/06/15
#  * Added mode selection feature, normal mode and random mode.
#

readonly DATA_FILE='data.txt'

handler() {
  echo "Quit."
  kill -9 $$
}
trap handler 0 1 2 3 15

main() {
  # Mode variable.
  # Normal mode : words are asked in order of data file.
  # Random mode : words are asked in random.
  readonly MODE_NORMAL=0
  readonly MODE_RANDOM=1
  declare -i mode=${MODE_NORMAL}

  # Argument processor.
  if [[ ${#} -eq 1 ]]; then
    case ${1} in
      'n' )
        mode=${MODE_NORMAL}
        echo "Normal mode"
        ;;
      'r' )
        mode=${MODE_RANDOM}
        echo "Random mode"
        ;;
      * )
        echo "Invalid argument"
        exit
        ;;
    esac
  else
    echo "Normal mode"
  fi

  declare -a word_vector
  declare -a comment_vector
  declare -a check_vector

  declare -i clear_count=0
  declare -i retry_flag=0
  declare -i word_id=0
  declare -i current_word_id=0
  local word=""
  local comment=""
  local input_buffer=""

  # The file is loaded.
  echo "open ${DATA_FILE}"
  while read -a buffer || [ "${buffer}" != "" ]; do
    if [[ "${buffer:0:1}" != "#" ]]; then
      word_vector+=(${buffer[0]})
      comment_vector+=( \
        $(echo "${buffer[@]:1:(${#buffer[@]}-1)}" | \
        sed -e 's/ \+/#/g' | \
        sed -e 's/\t\+/#/g'))
      check_vector+=(0)
    fi
  done < ${DATA_FILE}

  echo "----"
  echo "Total ${#word_vector[@]} words are loaded"
  echo 'Practice start'
  echo "----"

  while [[ 1 ]]; do
    # Word is selected according to the answer.
    # If unsuccessfully typed, same word.
    # If successfully typed, change word.
    if [[ ${retry_flag} -eq 0 ]]; then
      if [[ ${#check_vector[@]} -eq ${clear_count} ]]; then
        echo 'All words are done! Exit'
        exit 0
      fi

      case ${mode} in
        ${MODE_NORMAL} )
          while [[ ${check_vector[${word_id}]} -eq 1 ]]; do
            word_id=$(((${word_id} + 1) % ${#word_vector[@]}))
          done
          current_word_id=${word_id}
          word_id=$(((${word_id} + 1) % ${#word_vector[@]}))
          ;;
        ${MODE_RANDOM} )
          word_id=$(($RANDOM % ${#word_vector[@]}))
          while [[ ${check_vector[${word_id}]} -eq 1 ]]; do
            word_id=$(($RANDOM % ${#word_vector[@]}))
          done
          current_word_id=${word_id}
          ;;
        * ) ;;
      esac
    fi
    word=${word_vector[${current_word_id}]}
    comment=${comment_vector[${current_word_id}]}

    # Display target word and it's comment.
    echo "${word} / $(echo ${comment} | sed -e 's/#/ /g')"

    # Read user input.
    read -n${#word} input_buffer
    read -N 1024 -t 0.01
    echo ""

    # Judge
    if [[ ${input_buffer} = ${word} ]]; then
      echo -e "\e[32m>Excellent!\e[m"

      if [[ ${retry_flag} -eq 0 ]]; then
        # 1st time clear, check the word.
        check_vector[${current_word_id}]=1
        clear_count=$((${clear_count} + 1))
      fi

      retry_flag=0
    else
      echo -e "\e[31m>Incorrect!\e[m"

      # diff is shown.
      for i in $(seq 0 $((${#word} - 1))); do
        if [[ ${input_buffer:${i}:1} = ${word:${i}:1} ]]; then
          # Blue
          echo -e -n "\e[36m${input_buffer:${i}:1}\e[m"
        else
          # Red
          echo -e -n "\e[31m${input_buffer:${i}:1}\e[m"
        fi
      done
      echo ""

      retry_flag=1
    fi
    echo ""

  done

  echo 'Practice Finished.'
}
main ${@}
