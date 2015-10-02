# Automation Test for KAKA 


- This project is driven by Appium and created by Elaine Ang.

- The folder "otms_RegTest" is the automation test of oTMS system written by Chao Li.

- There are two files in "otms_RegTest--bin"--"KAKA_Methods" and "interact_with_kaka"--trying to build the connection between KAKA and oTMS system automation.


# Environment Setup 


- Here is the official document for appium command line setup on Mac OS X.  

	[appium setup](http://appium.io/slate/en/tutorial/android.html?ruby#introduction)





- For instructions on Windows or Linux, please check the information on Appium's official website. 

	[appium official website](http://appium.io/)





- For more detailed information about appium, please check the official API Reference.

	[appium API Reference](http://appium.io/slate/en/v1.0.0/?python#)





- There are also other good blog resources for appium.

	[CSDN BLOG](http://blog.csdn.net/column/details/appiumpriciplekzhu.html)
    
	[CSDN BLOG 2](http://www.cnblogs.com/nbkhic/p/3803804.html)





- Note:



    - In order to execute the command "cd appium; ./reset.sh --android", you need Android API 18 on your computer.
    
    - If you are using Python3, use "pip3" instead of "pip" for installing python bundles.

    - For homebrew update, if "brew update" does not work, try the following command:
    
```
        cd brew --prefix

        git remote add origin https://github.com/mxcl/homebrew.git

        git fetch origin

        git reset --hard origin/master 
```




# Run Test 


- In order to run the test, you need Ruby and Python Interpreter installed, along with the required packages. 

    * For python, you need 'Appium-Python-Client', 'selenium' and 'pyYaml'.
    
    * The complete list for required ruby gems is listed in the 'Gemfile.lock' in the folder 'otms_RegTest'. Note that for ruby, gems' version matters.


- Although there is a test case for login, it is recommanded that you login manually, because some phones do not have the permission of reading SMS and get activation code.


- However, confict appears when encountering the following situation:

    * The design of KAKA requires the instruction page to be loaded before any other operations. 
    
    * Appium need its own cache of loading instruction page for running follwing test cases, while doing login manually cannot provide cache for appium.


- The current walk-around for avoiding the conflict before and successfully run the test cases is as following:

    1. Download the repository, open the file "run_test--run_test.py", take away the comments in this file that comment two test cases, save it. 
 
    2. Open your command line tools, cd to the root folder, run `python3 run.py`. (It does not require KAKA installed on the phone, but the .apk file in the root folder.)
 
    3. The process may fail on login, if the phone block the permission of reading SMS. Let it fail. Then login manually.
 
    4. Open the file "run_test--run_test.py" again, comment the first two test cases ("test_change_env" and "test_login"), save. 
    
    6. Change the device_id value in config.yml. The device id can be found using ddms in android sdk tools folder. 
 
    5. Run `python3 run.py` again. It should work now.


- The result for the test can be seen in 'test_for_kaka_result.html' generated after tests finish and located in the root folder.


- Appium itself is unstable sometimes. Thus, if any case end up with an "E"(error) or "F"(fail) instead of "."(pass), 
    consider comment other test cases in "run_test.py" and run that one individually again using `python3 run.py` before claiming the fail of that case.


- PS. The walk-around is pretty lame, please let me know if there is any solution for this. Thanks in advance!

- PPS. For anyone who spend time reading this readme file till this line, sorry in advance for the sufferings brought by this project. I tried my best...



# Contact 

If you have any related question, please send an email to ra1695@nyu.edu
