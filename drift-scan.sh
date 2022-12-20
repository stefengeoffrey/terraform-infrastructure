#!/usr/bin/env bash
TERRAGRUNT_CONFIG="terragrunt.hcl"
WORKING_DIR=`pwd`
REPORT="$WORKING_DIR/report.log"
TERRAGRUNT_MODULES=`find . -name "$TERRAGRUNT_CONFIG"`
RESULT_CODE=0
touch $REPORT

for MODULE in $TERRAGRUNT_MODULES
do
  MODULE_DIR=`dirname $MODULE`
  cd $MODULE_DIR
  terragrunt plan --terragrunt-non-interactive --detailed-exitcode -lock=false > plan.log 2>&1
  EXIT_CODE=$?
  if [ $EXIT_CODE -eq 0 ]; then
    echo -e "=== \U2705 $MODULE_DIR Passed  ===" | tee -a $REPORT
  elif [ $EXIT_CODE -eq 1 ]; then
    echo -e "=== \U26D4 $MODULE_DIR Error Occured ===" | tee -a $REPORT
    cat plan.log >> $REPORT
    RESULT_CODE=1
  else [ $EXIT_CODE -eq 2 ];
    echo -e "=== \U1F6A7 $MODULE_DIR Drift Detected ===" | tee -a $REPORT
    cat plan.log >> $REPORT
    RESULT_CODE=1
  fi
  rm plan.log
  cd $WORKING_DIR
done

echo "===================="
echo "====== REPORT ======"
echo "===================="
cat $REPORT
exit $RESULT_CODE
