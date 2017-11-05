# fit5140-lazy-mail

Assignment 3 for FIT5140

by Yingchen Liu and Qiuxian Cai

## Deploy the server
* Install PM2 both localy and on the server
* Install MongoDB on the server
* Deploy

  ```
  $ pm2 deploy ecosystem.config.js production
  ```

## Install mailbox-end app on Raspberry Pi
* Install OpenCV
* Copy `raspberrypi` folder to the Raspberry Pi 
* Run the program

  ```
  $ python3 main.py
  ```

## Upload code to the ardunio
* Install Ardunio IDE
* Open the project in `ardunio` folder
* Select board Ardunio Nano
* Upload the code

## Install the app on iPhone
* Open the project in `ios/lazymails` folder
* Run