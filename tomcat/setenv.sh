#!/bin/sh
JAVA_OPTS="-Xms2400m -Xmx2400m -Xmn600m -XX:TargetSurvivorRatio=90 -XX:MaxTenuringThreshold=30 -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCTimeStamps -Xloggc:gc.log -XX:+UseParNewGC -XX:ParallelGCThreads=2 -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=80 -XX:MaxPermSize=256m -XX:PermSize=128m -Xss256k"
