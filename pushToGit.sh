isError=false;
function test {
    "$@"
    status=$?
    if [ $status -ne 0 ]; then
echo "error with $1"
        isError=True
    fi
return $status
}

test git ls-remote &> /dev/null
echo "The value is $isError"


#check if remote repository is defined for
if $isError; then
git remote add origin https://github.com/sfdeveloperhub/orgcoderepov2.git
fi

git add .
git commit
git push origin master
