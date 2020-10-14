import os
import sys
import re
import requests
import simplejson
from optparse import OptionParser

import utils

from __exceptions__ import formattedException

'''
Requires:  requests   http://docs.python-requests.org/en/latest/
'''

__version__ = '1.0.0'

import logging
from logging import handlers

__PROGNAME__ = os.path.splitext(os.path.basename(sys.argv[0]))[0]
LOG_FILENAME = os.sep.join([os.path.dirname(sys.argv[0]),'%s.log' % (__PROGNAME__)])

class MyTimedRotatingFileHandler(handlers.TimedRotatingFileHandler):
    def __init__(self, filename, maxBytes=0, when='h', interval=1, backupCount=0, encoding=None, delay=False, utc=False):
	handlers.TimedRotatingFileHandler.__init__(self, filename=filename, when=when, interval=interval, backupCount=backupCount, encoding=encoding, delay=delay, utc=utc)
	self.maxBytes = maxBytes
    
    def shouldRollover(self, record):
	response = handlers.TimedRotatingFileHandler.shouldRollover(self, record)
	if (response == 0):
	    if self.stream is None:                 # delay was set...
		self.stream = self._open()
	    if self.maxBytes > 0:                   # are we rolling over?
		msg = "%s\n" % self.format(record)
		try:
		    self.stream.seek(0, 2)  #due to non-posix-compliant Windows feature
		    if self.stream.tell() + len(msg) >= self.maxBytes:
			return 1
		except:
		    pass
	    return 0
	return response

logger = logging.getLogger(__PROGNAME__)
handler = logging.FileHandler(LOG_FILENAME)
#handler = handlers.TimedRotatingFileHandler(LOG_FILENAME, when='d', interval=1, backupCount=30, encoding=None, delay=False, utc=False)
#handler = MyTimedRotatingFileHandler(LOG_FILENAME, maxBytes=1000000, when='d', backupCount=30)
#handler = handlers.RotatingFileHandler(LOG_FILENAME, maxBytes=1000000, backupCount=30, encoding=None, delay=False)
formatter = logging.Formatter('%(asctime)s %(levelname)s %(message)s')
handler.setFormatter(formatter)
handler.setLevel(logging.DEBUG)
logger.addHandler(handler) 
print 'Logging to "%s".' % (handler.baseFilename)

ch = logging.StreamHandler()
ch_format = logging.Formatter('%(asctime)s - %(message)s')
ch.setFormatter(ch_format)
ch.setLevel(logging.DEBUG)
logger.addHandler(ch)

logging.getLogger().setLevel(logging.DEBUG)

__username__ = 'nscahelper'
__password__ = utils.md5('peekab00')

__find_nagios__ = 'find /usr -iname nagios'

__find_send_nsca_cfg__ = 'find /etc -iname send_nsca.cfg'

__re1__ = re.compile(r"\A(?P<num>[0-9]*)\sdata\spacket.*\ssent\sto\shost\ssuccess.*")

__PARTITIONS__ = 'PARTITIONS'

__DISKS__ = 'DISKS'

__get_partition_name__ = "df | awk '{print $1}' | grep %s"

if __name__ == '__main__':
    '''
    python nsca-helper-client.py

	/nsca/nagios/create/config
	{"oper": "login",
	"username": "nscahelper",
	"password": "103136174d231aabe1de8feaf9afc92f",
	"target": "nagios.cfg",
	"cfg": "remote2_nagios2",
	"partitions": "awk '{print $4}' /proc/partitions | sed -e '/name/d' -e '/^$/d' -e '/[1-9]/!d'",
	"host1": {
		"use": "generic-host",
		"host_name": "remote1",
		"alias": "remote1",
		"address": "0.0.0.0"
	},
	"command1": {
		"command_name": "dummy_command2",
		"command_line": "echo \"0\""
	          },
	  "service1": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"CPULoad",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service2": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"CurrentUsers",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service3": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"PING",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service4": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"SSH",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service5": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"TotalProcesses",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service6": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"ZombieProcesses",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          }
	  }
    '''
    parser = OptionParser("usage: %prog [options]")
    parser.add_option("-o", "--host",action="store", type="string", dest="host",help="host option")
    parser.add_option("-i", "--ip",action="store", type="string", dest="ip",help="ip address option")
    parser.add_option("-u", "--url",action="store", type="string", dest="url",help="url option")
    parser.add_option("-j", "--json",action="store", type="string", dest="json",help="config json option")
    parser.add_option("-c", action="store_true", dest="iscreate",help="create option")
    parser.add_option("-m", action="store_true", dest="ismonitor",help="monitor option")
    
    options, args = parser.parse_args()

    logger.info('iscreate=%s' % (options.iscreate))
    logger.info('ismonitor=%s' % (options.ismonitor))
    isUsingLinux = utils.isUsingLinux or utils.isBeingDebugged
    if (isUsingLinux):
	__config__ = utils.SmartObject()
	logger.debug('(+++) options.json=%s' % (options.json))
	if (options.json) and (os.path.exists(options.json)):
	    json = ''.join(utils.readfile(options.json))
	    __config__ = utils.SmartObject(args=simplejson.loads(json))
	    logger.debug('(+++) __config__=%s' % (__config__))
	else:
	    logger.warning('Missing config.json from the -j option so using default services.')

	services = ["CPU Load","Current Users","PING","SSH","Total Processes","Zombie Processes"]
	
	if (len(__config__.keys()) > 1):
	    services = [k for k in __config__.keys() if (k not in ['DISKS','__dict__','PARTITIONS'])]
	    logger.debug('(+++) services=%s' % (services))

	if (options.url):
	    if (options.host):
		if (options.ip):
		    if (options.iscreate):
			logger.info('Create mode !!!')
			payload = utils.SmartObject()

			payload.oper = "login"
			payload.username = __username__
			payload.password = __password__
			payload.target = "nagios.cfg"
			payload.cfg = "%s_nagios2" % (options.host)
			payload.partitions = "awk '{print $4}' /proc/partitions | sed -e '/name/d' -e '/^$/d' -e '/[1-9]/!d'"
			
			host1 = utils.SmartObject()
			host1.use = "generic-host"
			host1.host_name = options.host
			host1.alias = options.host
			host1.address = options.ip
			payload.host1 = host1.__dict__
			
			command1 = utils.SmartObject()
			command1.command_name = "dummy_command_%s" % (options.host)
			command1.command_line = "echo \"0\""
			payload.command1 = command1.__dict__
			
			if (payload.partitions):
			    logger.info('1. payload.partitions=%s' % (payload.partitions))
			    results = utils.shellexecute(payload.partitions)
			    logger.info('2 results=%s' % (results))
			    partition_names = [str(r).strip() for r in results[0]] if (utils.isList(results)) else results
			    logger.info('3 payload.partition_names=%s' % (payload.partition_names))
			    for partition in partition_names:
				services.append(partition)

			count = 1
			for svc in services:
			    service = utils.SmartObject()
			    service.use = "generic-service"
			    service.host_name = options.host
			    service.service_description = svc
			    service.active_checks_enabled = "0"
			    service.passive_checks_enabled = "1"
			    service.check_command = command1.command_name
			    payload['service%s' % (count)] = service.__dict__
			    count += 1

			headers = {'Content-Type':'application/json', 'Accept':'application/json'}
			r = requests.post('%s/nsca/nagios/create/config' % (options.url),data=simplejson.dumps(payload.__dict__), headers=headers)
			logger.debug('r.status_code=%s' % (r.status_code))
		    elif (options.ismonitor):
			logger.info('monitor mode !!!')
			
			def monitor_service(svc,symbol,value):
			    cmd = __config__[svc]
			    cName = cmd.split()[0]
			    __cmd__ = os.sep.join([__plugins__,cName])
			    if (os.path.exists(__cmd__)):
				cmd = cmd.replace(cName,__cmd__).replace(symbol,value)
				logger.debug('(+++) %s=%s' % (svc,cmd))

				__results__ = utils.shellexecute(cmd)
				results = [str(item).strip() for item in __results__[0]]
				retcode = [str(item).strip() for item in __results__[-1]]
				logger.info('(+++) cmd-->results=%s' % (results))
				logger.info('(+++) cmd-->retcode=%s' % (retcode))
				
				data = "%s\\t%s\\t%s\\t%s\n" % (options.host, svc, 0 if (len(retcode) == 0) else 1, results[0])
				logger.debug('(+++) data=%s' % (data))

				payload = utils.SmartObject()
	
				payload.oper = "login"
				payload.username = __username__
				payload.password = __password__

				payload.send_nsca = data

				__cfg__ = None
				__results__ = utils.shellexecute(__find_send_nsca_cfg__)
				results = [str(f).strip() for f in __results__[0] if (os.path.exists(str(f).strip()))]
				if (len(results) > 0):
				    __cfg__ = results[0]
				logger.info('__results__=%s [%s]' % (__results__,len(__results__)))
				logger.info('__cfg__=%s' % (__cfg__))

				payload.cfg = __cfg__

				headers = {'Content-Type':'application/json', 'Accept':'application/json'}
				r = requests.post('%s/nsca/nagios/send/nsca' % (options.url),data=simplejson.dumps(payload.__dict__), headers=headers)
				logger.debug('r.status_code=%s' % (r.status_code))
				logger.debug('r.json()=%s' % (r.json()))
				
				if (r.status_code == 200):
				    try:
					response = utils.SmartObject(args=r.json())
					logger.debug('response=%s' % (response.__dict__))
					matches = __re1__.search(response.status[0] if (utils.isList(response.status)) else response.status) if (response.status) else None
					if (matches):
					    groups = utils.SmartObject(args=matches.groupdict())
					    logger.debug('(+++) matches=%s [%s]' % (matches,groups.__dict__))
					    
					    if (groups.num):
						logger.debug('(+++) groups.num=%s' % (groups.num))
				    except Exception, ex:
					logger.exception('EXCEPTION: %s' % (utils.formattedException(details=ex)))

			__plugins__ = None
			__results__ = utils.shellexecute(__find_nagios__)
			results = [os.sep.join([str(f).strip(),'plugins']) for f in __results__[0] if (os.path.exists(os.sep.join([str(f).strip(),'plugins'])))]
			if (len(results) > 0):
			    __plugins__ = results[0]
			logger.info('__results__=%s [%s]' % (__results__,len(__results__)))
			logger.info('results=%s' % (results))
			
			logger.debug('(+++) __plugins__=%s [%s]' % (__plugins__,os.path.exists(__plugins__)))
			if (__plugins__) and (os.path.exists(__plugins__)):
			    for svc in services:
				monitor_service(svc,'{{host}}',options.host)

			    others = list(set(__config__.keys()) - set(services) - set(['__dict__']))
			    logger.debug('(+++) others=%s' % (others))
			    
			    if (__PARTITIONS__ in others):
				p_cmd = __config__[__PARTITIONS__]

				partitions = None
				__results__ = utils.shellexecute(p_cmd)
				results = [str(f).strip() for f in __results__[0]]
				if (len(results) > 0):
				    partitions = results
				logger.info('__results__=%s [%s]' % (__results__,len(__results__)))
				logger.info('partitions=%s' % (partitions))
				
				if (partitions):
				    if (__DISKS__ in others):
					disks = __config__[__DISKS__]
					logger.debug('(+++) disks=%s' % (disks))
					for p in partitions:
					    partition_name = None
					    __results__ = utils.shellexecute(__get_partition_name__ % p)
					    results = [str(f).strip() for f in __results__[0]]
					    if (len(results) > 0):
						partition_name = results[0] if (utils.isList(results)) else results
					    logger.info('__results__=%s [%s]' % (__results__,len(__results__)))
					    logger.info('partition_name=%s' % (partition_name))

					    monitor_service(__DISKS__,'{{partition}}',partition_name)
			else:
			    logger.error('Cannot determine location of nagios plugins directory.')
		    else:
			logger.error('Cannot determine what you want me to do ?!?')
		else:
		    logger.error('Cannot the ip (-i) you want me to use ?!?')
	    else:
		logger.error('Cannot the host (-h) you want me to use ?!?')
	else:
	    logger.error('Cannot the url (-u) you want me to use ?!?')
    else:
	logger.error('Linux is required ?!?')
    