import ftplib
import sys

filName = sys.argv[1]
session = ftplib.FTP('192.168.1.60','michael','Michael010904')
file = open(filName,'rb')
session.storbinary('STOR '+filName,file)
file.close()
session.quit()
