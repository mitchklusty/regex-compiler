#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
PASS=0
FAIL=0
TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local input_file="$2"
    local expected_result="$3"
    
    echo "Running test: $test_name"
    ((TOTAL++))
    
    # Create temporary file with test input
    echo "$input_file" > temp_test.regex
    
    # Run the compiler
    ./parse temp_test.regex > temp_out.txt 2> temp_err.txt
    local exit_code=$?
    
    # Get output and error
    local output=$(cat temp_out.txt)
    local error=$(cat temp_err.txt)
    
    # Check if the result matches expectation
    if [ "$expected_result" == "success" ] && [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $test_name"
        ((PASS++))
    elif [ "$expected_result" == "fail" ] && [ $exit_code -ne 0 ]; then
        echo -e "${GREEN}PASS${NC}: $test_name (expected failure)"
        echo "Error message: $error"
        ((PASS++))
    else
        echo -e "${RED}FAIL${NC}: $test_name"
        echo "Expected: $expected_result, Got exit code: $exit_code"
        echo "Output: $output"
        echo "Error: $error"
        ((FAIL++))
    fi
    
    # Cleanup
    rm -f temp_test.regex temp_out.txt temp_err.txt
    echo ""
}

# Make sure the compiler is built
make clean && make

echo "=== Testing Regex Compiler ==="
echo ""

# Parsing Tests

run_test "tailingdash" "/\"a\" & [a-z]/" "success" 

run_test "lotsofparens" "/((\"h\"))/" "success" 

run_test "rngcompliment" "/[^a-z]/" "success" 

run_test "wild" "/.+/" "success" 

run_test "multipletails" "/\"a\"+*?/" "success" 

run_test "range" "/[a-z]/" "success" 

run_test "escape" "/\"%x7;%x0;\"/" "success" 

run_test "numeric" "/\"%x7;%x0;\"/" "success" 

run_test "digit" "/\"0\" | [1-9][0-9]+/" "success" 

run_test "literal" "/\"this is a literal\"/" "success" 

run_test "digit_sys" "const NonZeroDigit = /[1-9]/
const Digit = /[0-9]/

/\"0\" | \${NonZeroDigit}\${Digit}+/" "success" 

run_test "optionseq" "/\"this is a literal\" (\"x\" | \"y\")/" "success" 

run_test "option" "/\"this is a literal\"?/" "success" 

run_test "lrcombo" "/\"h\"[aeiou]?/" "success" 

run_test "unicode" "/\"unicode literal\" \"🌶\"*/" "success" 

run_test "tailingdash" "/\"a\" & (\"b\" | \"c\" & [a-z])/" "fail" 

run_test "lotsofparens" "/(())/" "fail" 

run_test "rngcompliment" "/^[a-z]/" "fail" 

run_test "wild" "/!(\"abc\" & [a-z])/" "fail" 

run_test "multipletails" "/???/" "fail" 

run_test "range" "/[a-z]" "fail" 

run_test "escape" "/%x0;/" "fail" 

run_test "numeric" "/9/" "fail" 

run_test "digit" "/\"0\" | 1-90-9]+/" "fail" 

run_test "literal" "/\"this is a literal/" "fail" 

run_test "digit_sys" "const NonZeroDigit = [1-9]
const Digit [0-9]

/\"0\" | \${NonZeroDigit}\${Digit}+/" "fail" 

run_test "optionseq" "/\"this is a literal\" \"x\" | \"y\")/" "fail" 

run_test "option" "/\"this is a literal\"#/" "fail" 

run_test "lrcombo" "/\"h\"aeiou]?/" "fail" 

run_test "unicode" "const s_id = /\"unicode literal\" \"🌶\"*/" "fail"

# Compiler Tests


run_test "Basic Literal" "/\"this is a literal\"/" "success"

run_test "Unicode Literal" "/\"unicode literal\" \"🌶\"*/" "success"

run_test "Escaped Characters" "/\"%x7;%x0;\"/" "success"

run_test "String Range" "/\"h\"[aeiou]+/" "success"

run_test "Number" "/[+-]? (\"0\" | [1-9][0-9]+)/" "success"

run_test "Variable Calling" "const NonZeroDigit = /[1-9]/
const Digit = /[0-9]/
/[+-]? (\"0\" | \${NonZeroDigit}\${Digit}+)/" "success"

# 
run_test "Filename" "const Filename = /\"test\"/
/\${Filename} & .+ \".txt\"/" "success"

# Defining a variable
run_test "Variable Definition" "const s_re = /[a-z]/
" "fail"

# Valid basic regex
run_test "Basic valid regex" "/\"a\"|\"b\"/" "success"

# Valid regex with a constant definition
run_test "Valid constant definition" "const DIGIT = /[0-9]/
/\${DIGIT}/" "success"

# Invalid regex with undefined reference
run_test "Undefined reference" "/\${UNDEFINED}/" "fail"

# Valid regex with multiple constant definitions
run_test "Multiple constant definitions" "const DIGIT = /[0-9]/
const ALPHA = /[a-zA-Z]/
/\${DIGIT}|\${ALPHA}/" "success"

# Valid regex with nested constants
run_test "Nested constants" "const DIGIT = /[0-9]/
const NUM = /\${DIGIT}+/
/\${NUM}/" "success"

# Invalid regex with invalid unicode escape
run_test "Invalid unicode escape" "/\"%xZZZZ;\"/" "fail"

# Valid regex with valid unicode escape
run_test "Valid unicode escape" "/\"%x0041;\"/" "success"

# Invalid regex with syntax error
run_test "Syntax error" "/\"a\"|*\"b\"/" "fail"

# Valid regex with complex pattern
run_test "Complex pattern" "const DIGIT = /[0-9]/
const ALPHA = /[a-zA-Z]/
const ALNUM = /\${DIGIT}|\${ALPHA}/
/\${ALNUM}+(.\${ALNUM}+)*\"@\"\${ALPHA}+(.\${ALPHA}+)*/" "success"

# Test 10: Invalid regex with redefined constant
run_test "Redefined constant" "const DIGIT = /[0-9]/
const DIGIT = /[0-8]/
/\${DIGIT}/" "fail"

# Summary
echo "=== Test Results ==="
echo "Passed: $PASS / $TOTAL"
echo "Failed: $FAIL / $TOTAL"

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi