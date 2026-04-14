pusher()
{
	clear
	git add . 
	echo
	echo "git add all executed successfully"
	echo
	git status
	echo
	vared -p 'Write your commit here: ' -c tmp
	git commit -m $tmp 
	echo 
	git push
}
