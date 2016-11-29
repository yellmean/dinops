#!/usr/bin/python
#coding=utf8

import re
import time
import memcache
import telnetlib
import pymysql

#Memcached连接信息
memcachedConfig = {
    'host': '192.168.0.189',
    'port': '11211',
    'user': '',
    'password': ''
}

#MySQL连接信息
mysqlConfig = {
    'host': '192.168.0.189',
    'port': 3306,
    'user': 'root',
    'password': 'dingjian',
    'database': 'dc_alonetest',
    'charset': 'utf8'
}

#OnlineKey有效时间(分钟)
expireTime = 60

#程序循环执行周期（分钟）
sleepTime = 5


def initKeys():
    tn = telnetlib.Telnet(memcachedConfig['host'], memcachedConfig['port'])
    tn.set_debuglevel(2)
    mc = memcache.Client([memcachedConfig['host']+':'+memcachedConfig['port']], debug=0)
    for slab_stats in mc.get_slabs()[0][1]:
        tn.write('stats cachedump %s 0\n' % slab_stats)
    tn.write('quit\n')
    results = tn.read_all().split('ITEM ')[1:]
    for result in results:
        items =result.split(' ')[0:]
        if int(items[3]) > (time.time()):
            localtime = time.localtime(int(items[3]))
            fExpireTime = time.strftime("%Y-%m-%d %H:%M:%S", localtime)
            fId = items[0].replace('%7C', '|')
            item = items[0].split('%7C')
            if len(item) != 4:
                continue
            fcuNum = items[0].split('%7C')[1]
            fClient = items[0].split('%7C')[2]
            fClientType = re.findall(r'PC|MOBILE', fClient)[0]
            fPersonId = items[0].split('%7C')[3]
            #print fId,fcuNum,fClientType,fPersonId
            conn = pymysql.connect(
                host= mysqlConfig['host'],
                port= mysqlConfig['port'],
                user= mysqlConfig['user'],
                passwd= mysqlConfig['password'],
                db= mysqlConfig['database'],
                charset= mysqlConfig['charset']
            )
            cur = conn.cursor()
            cur.execute("insert into t_bd_onlinekey values(%s,%s,%s,%s,%s)", (fId, fcuNum, fClientType, fPersonId, fExpireTime))
            conn.commit()
            cur.close()
            conn.close()

def onlineKeys():
    tn = telnetlib.Telnet(memcachedConfig['host'], memcachedConfig['port'])
    tn.set_debuglevel(2)
    mc = memcache.Client([memcachedConfig['host']+':'+memcachedConfig['port']], debug=0)
    for slab_stats in mc.get_slabs()[0][1]:
        tn.write('stats cachedump %s 0\n' % slab_stats)
    tn.write('quit\n')
    results = tn.read_all().split('ITEM ')[1:]
    for result in results:
        items =result.split(' ')[0:]
        if int(items[3]) - int(60*(expireTime-1)) > int(time.time()):
            localtime = time.localtime(int(items[3]))
            fExpireTime = time.strftime("%Y-%m-%d %H:%M:%S", localtime)
            fId = items[0].replace('%7C', '|')
            item = items[0].split('%7C')
            if len(item) != 4:
                continue
            fcuNum = items[0].split('%7C')[1]
            fClient = items[0].split('%7C')[2]
            fClientType = re.findall(r'PC|MOBILE', fClient)[0]
            fPersonId = items[0].split('%7C')[3]
            #print fId,fcuNum,fClientType,fPersonId
            conn = pymysql.connect(
                host= mysqlConfig['host'],
                port= mysqlConfig['port'],
                user= mysqlConfig['user'],
                passwd= mysqlConfig['password'],
                db= mysqlConfig['database'],
                charset= mysqlConfig['charset']
            )
            cur = conn.cursor()
            cur.execute("select fid from t_bd_onlinekey where fid = %s", fId)
            if len(cur.fetchall()):
                #print 'UPDATE'
                cur.execute("update t_bd_onlinekey set fExpireTime = %s where fID = %s",(fExpireTime, fId))
            else:
                #print 'INSERT'
                cur.execute("insert into t_bd_onlinekey values(%s,%s,%s,%s,%s)", (fId, fcuNum, fClientType, fPersonId, fExpireTime))
            conn.commit()
            cur.close()
            conn.close()

if __name__ == '__main__':
    while True:
        conn = pymysql.connect(
            host= mysqlConfig['host'],
            port= mysqlConfig['port'],
            user= mysqlConfig['user'],
            passwd= mysqlConfig['password'],
            db= mysqlConfig['database'],
            charset= mysqlConfig['charset']
        )
        cur = conn.cursor()
        cur.execute("select count(1) from t_bd_onlinekey")
        if cur.fetchone()[0] == 0:
            initKeys()
            #print 'Init'
        else:
            onlineKeys()
            #print 'Online'
        cur.close()
        conn.close()
        time.sleep(sleepTime*60)





