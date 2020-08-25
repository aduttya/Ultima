#!/usr/bin/env bash

function push {

	FILE=`sed -n 2p .test.cpp | cut --complement -d' ' -f1,2`.cpp

	cp .test.cpp Submissions/"$FILE"

	NAME="\ \*\tAuthor: Tanuj Raghav <anwailuisa>"
	DATE="\ \*\tDate: `date \"+%A, %B %d, %Y\"`   `date \"+%X\"`"

	FILE="Submissions/$FILE"

	sed -i "1a $NAME" "$FILE"
	sed -i "2a $DATE" "$FILE"

	if [[ -n "$1" ]]; then
		COMMENT="\ \*\tComment: $1"
		sed -i "5a $COMMENT" "$FILE"
	fi

	git add "$FILE"

	echo "Submission #"`echo $(($(cat .submission-count)+1)) > .submission-count && cat .submission-count` > commit.msg

	echo `sed -n 4p "$FILE" | cut --complement -d'	' -f1` >> commit.msg
	echo `sed -n 5p "$FILE" | cut --complement -d'	' -f1` >> commit.msg

	if [[ -n "$1" ]]; then
		echo "Comment: $1" >> commit.msg
	fi

	git commit --quiet -F commit.msg

	git push --quiet origin master

	git log --decorate --max-count=1 | tail -n+3

	rm commit.msg

}

function submit {

	session_info=()

	if [ -s .cache ]; then
		session_info+="`head -n1 .cache` "
		session_info+="`tail -n1 .cache`"
	fi

	/usr/bin/python3 -c '

import sys, subprocess
from selenium import webdriver

def submit(*args):

	options=webdriver.ChromeOptions()

	options.add_argument("--no-sandbox")
	options.add_argument("--start-maximized")

	driver=webdriver.Chrome(executable_path=r"/usr/bin/chromedriver",options=options)

	if args[0][3] != "":
		driver=webdriver.Remote(command_executor=args[0][3])
		driver.quit()
		driver.session_id=args[0][4]

	else:
		url=driver.command_executor._url
		id=driver.session_id

		subprocess.run("echo "+url+" > .cache",shell=True)
		subprocess.run("echo "+id+" >> .cache",shell=True)

	driver.get(args[0][1])

	js="""
	var list = document.getElementsByTagName("option");
	for(var i=0;i<list.length;i++){
		if(list[i].innerHTML==arguments[0]){
				list[i].setAttribute("selected","selected");
			}
		}
	"""

	driver.execute_script(js,"GNU G++17 7.3.0")

	driver.find_element_by_xpath("//input[@name='sourceFile']").send_keys(args[0][2]);
	driver.find_element_by_xpath("//input[@value='Submit']").click();

	return driver

driver=submit(sys.argv)

	' \
	"`sed -n 3p ".test.cpp" | cut --complement -d':' -f1 | cut -d' ' -f2`" \
	"`pwd`/.test.cpp" \
	"`echo ${session_info[@]} | cut -d' ' -f1`" \
	"`echo ${session_info[@]} | cut -d' ' -f2`"

}

function execute {

	unbuffer g++ --std=c++17 -Wall -O2 -o output.out .test.cpp 2>&1 | tee tmp.log

	[ -f .input.in ] || touch .input.in

	if [ ! -s tmp.log ]; then

		if [[ $1 == "in" ]]; then
			nano .input.in
		fi

		./output.out < .input.in

		rm output.out
	fi

	rm tmp.log

}

function main {

	case $1 in 

		push) push "$2" ;;

		submit) submit ;;

		*) execute $1 ;;

	esac

}

main $1 "$2"
