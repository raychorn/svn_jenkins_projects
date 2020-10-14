import os
import sys
import web
import simplejson

import utils

from __exceptions__ import formattedException

'''
Requires: web.py --> http://webpy.org/
'''

import threading

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

urls = (
    '/', 'Index',
    '/nsca/(.+)', 'NSCAHelper',
    '/nsca', 'NSCAHelper',
    '/setwindowsagentaddr', 'Nothing',
    '/setwindowsagentaddr/', 'Nothing',
)

### Templates
render = web.template.render('templates', base='base')

web.template.Template.globals.update(dict(
    datestr = web.datestr,
    render = render
))

def notfound():
    return web.notfound("Sorry, the page you were looking for was not found.  This message may be seen whenever someone tries to issue a negative number as part of the REST URL Signature and this is just not allowed at this time.")

__index__ = '''
<html>
<head>
    <title>(c). Copyright 2013, AT&T, All Rights Reserved.</title>
    <style>
        #menu {
            width: 200px;
            float: left;
        }
    </style>
</head>
<body>

<ul id="menu">
    <li><a href="/">Home</a></li>
</ul>

<p><b>UNAUTHORIZED ACCESS</b></p>

</body>
</html>
'''

class Index:

    def GET(self):
        """ Show page """
	s = '%s %s' % (__PROGNAME__,__version__)
	return __index__

class Nothing:
    def POST(self):
	web.header('Content-Type', 'text/html')
	return __index__

__username__ = 'nscahelper'
__password__ = utils.md5('peekab00')

class NSCAHelper:

    def GET(self):
        web.header('Content-Type', 'text/html')
	return __index__

    def POST(self,uri):
	'''
	/nsca/nagios/update/config
	{ "oper":"login",
	  "username":"nscahelper",
	  "password":"103136174d231aabe1de8feaf9afc92f",
	  "target":"nagios.cfg",
	  "cfg":"remote1_nagios2",
	  "service1": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"DISK_1",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          },
	  "service2": { "use":"generic-service",
	                "host_name":"remote1",
			"service_description":"DISK_2",
			"active_checks_enabled":"0",
			"passive_checks_enabled":"1",
			"check_command":"dummy_command2"
	          }
	  }

	/nsca/nagios/send/nsca
	{ "oper":"login",
	  "username":"nscahelper",
	  "password":"103136174d231aabe1de8feaf9afc92f",
	  "send_nsca": "localhost\\tDummy Service\\t2\\tlocalhost Mon Dec 23 22:03:50 UTC 2013",
	  "cfg":"/etc/send_nsca.cfg"
	}

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
	logger.info('1. uri=%s' % (uri))
	web.header('Content-Type', 'application/json')
	logger.info('2. web.data()=%s' % (web.data()))
	d = {}
	status = ''
	try:
	    payload = utils.SmartObject(simplejson.loads(web.data()))
	except Exception, ex:
	    payload = utils.SmartObject()

	    content = formattedException(details=ex)
	    logger.exception(content)
	    d['exception1'] = content
	try:
	    nagios_update_config = 'nagios/update/config'
	    nagios_create_config = 'nagios/create/config'
	    if (uri in [nagios_update_config,nagios_create_config]):
		logger.info('3. payload.oper=%s' % (payload.oper))
		if (payload.oper == 'login'):
		    logger.info('4. payload.username=%s' % (payload.username))
		    logger.info('5. payload.password=%s' % (payload.password))
		    if ( (payload.username == __username__) and (payload.password == __password__) ):
			logger.info('6. payload.cfg=%s [%s]' % (payload.cfg,(payload.cfg is not None)))
			if (payload.cfg is not None):
			    logger.info('7. utils.isUsingLinux=%s' % (utils.isUsingLinux))
			    nagios_cfg = str(payload.target) if (payload.target) else 'nagios.cfg'
			    if (utils.isUsingLinux):
				if (nagios_cfg):
				    if (payload.cfg):
					__cfg__ = None
					__nagios_cfg__ = None
					for top,dirs,files in utils.walk('/usr'):
					    #if (top.find('/usr/lib') > -1):
						#logger.info('8. top=%s' % (top))
					    if (nagios_cfg in files):
						#logger.debug('9. top=%s' % (top))
						__nagios_cfg__ = os.sep.join([top,nagios_cfg])
						logger.debug('10. __nagios_cfg__=%s [%s]' % (__nagios_cfg__,os.path.exists(__nagios_cfg__)))
					for top,dirs,files in utils.walk('/etc'):
					    #logger.info('11. top=%s' % (top))
					    if (top.find('nagios') > -1):
						#logger.debug('12. top=%s' % (top))
						if (nagios_cfg in files):
						    logger.debug('13. top=%s' % (top))
						    __nagios_cfg__ = os.sep.join([top,nagios_cfg])
						    logger.debug('14. __nagios_cfg__=%s [%s]' % (__nagios_cfg__,os.path.exists(__nagios_cfg__)))
					if (__nagios_cfg__) and (os.path.exists(__nagios_cfg__)):
					    logger.debug('20. __nagios_cfg__=%s [%s]' % (__nagios_cfg__,os.path.exists(__nagios_cfg__)))
					    for top,dirs,files in utils.walk(os.path.dirname(__nagios_cfg__)):
						logger.debug('21. top=%s' % (top))
						target_cfg = payload.cfg+'.cfg'
						for f in files:
						    #logger.debug('22 f (%s) == target (%s) [%s]' % (f,target_cfg,(f == target_cfg)))
						    if (f == target_cfg):
							__cfg__ = os.sep.join([top,f])
							break
						logger.debug('23. __cfg__=%s' % (__cfg__))
						if (uri in [nagios_create_config]) and (__cfg__ is None):
						    __cfgd__ = os.sep.join([os.path.dirname(__nagios_cfg__),'conf.d'])
						    if (os.path.exists(__cfgd__)):
							__cfg__ = __cfgd__
						    __cfg__ = os.sep.join([__cfg__,target_cfg])
						    logger.debug('24. __cfg__=%s' % (__cfg__))
						logger.debug('25. __cfg__=%s [%s]' % (__cfg__,os.path.exists(__cfg__) if (__cfg__) else None))
						if (payload.partitions):
						    logger.info('26. payload.partitions=%s' % (payload.partitions))
						    results = utils.shellexecute(payload.partitions)
						    logger.info('26.1 results=%s' % (results))
						    payload.partition_names = [str(r).strip() for r in results] if (utils.isList(results)) else results
						    logger.info('26.2 payload.partition_names=%s' % (payload.partition_names))
						if (__cfg__) and (os.path.exists(__cfg__)) and (uri in [nagios_update_config]):
						    logger.debug('27. handle_disk_services !!!')
						    status = utils.handle_disk_services(__cfg__, payload,logger)
						    d['status'] = status
						    logger.debug('28. status=%s' % (status))
						elif (__cfg__) and (uri in [nagios_create_config]):
						    logger.debug('29. handle_services !!!')
						    status = utils.handle_services(__cfg__, payload,logger)
						    d['status'] = status
						    logger.debug('30. status=%s' % (status))
						else:
						    logger.exception('WARNING: Cannot handle config file of "%s".' % (__cfg__))
						break
					else:
					    logger.exception('WARNING: Cannot determine location of "%s".' % (nagios_cfg))
				    else:
					logger.exception('WARNING: Cannot use or determine the valud of cfg which is "%s".' % (payload.cfg))
				else:
				    logger.exception('WARNING: Cannot use nagios.cfg reference of "%s".' % (nagios_cfg))
			    else:
				logger.exception('WARNING: Cannot run this program in any OS other than Linux, sorry.')
	    elif (uri == 'nagios/send/nsca'):
		logger.info('3. payload.oper=%s' % (payload.oper))
		if (payload.oper == 'login'):
		    logger.info('4. payload.username=%s' % (payload.username))
		    logger.info('5. payload.password=%s' % (payload.password))
		    if ( (payload.username == __username__) and (payload.password == __password__) ):
			logger.info('6. payload.cfg=%s [%s]' % (payload.cfg,(payload.cfg is not None)))
			if (payload.cfg is not None):
			    logger.info('7. utils.isUsingLinux=%s' % (utils.isUsingLinux))
			    send_nsca_cfg = str(payload.cfg)
			    if (utils.isUsingLinux):
				if (send_nsca_cfg) and (os.path.exists(send_nsca_cfg)):
				    logger.info('8. send_nsca_cfg=%s' % (send_nsca_cfg))
				    results = utils.shellexecute('which send_nsca')
				    logger.info('9. results=%s' % (results))
				    __send_nsca__ = results[0].split('\n')[0] if (utils.isList(results)) else results.split('\n')[0]
				    logger.info('10. __send_nsca__=%s' % (__send_nsca__))
				    if (__send_nsca__) and (os.path.exists(__send_nsca__)):
					logger.info('11. payload.send_nsca=%s' % (payload.send_nsca))
					__cmd__ = 'printf "%%s\\n" "%s" | %s -H 127.0.0.1 -p 5667 -c %s' % (payload.send_nsca.replace('\\t','\t'),__send_nsca__,send_nsca_cfg)
					logger.info('12. __cmd__=%s' % (__cmd__))
					results = utils.shellexecute(__cmd__)
					if (utils.isList(results)):
					    ', '.join(results)
					logger.info('13. results=%s' % (results))
					d['status'] = results
				    else:
					logger.exception('WARNING: Cannot determine location of send_nsca command from "%s".' % (__send_nsca__))
				else:
				    logger.exception('WARNING: Cannot determine location of "%s".' % (send_nsca_cfg))
	except Exception, ex:
	    content = formattedException(details=ex)
	    logger.exception(content)
	    d['exception2'] = content
	return simplejson.dumps(d)

app = web.application(urls, globals())
app.notfound = notfound

if __name__ == '__main__':
    '''
    python nsca-helper-daemon.py
    '''
    import re
    __re__ = re.compile(r"(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?):([0-9]{1,5})", re.MULTILINE)
    has_binding = any([__re__.match(arg) for arg in sys.argv])
    if (not has_binding):
	sys.argv.append('0.0.0.0:15667')
	
    def __init__():
	logger.info('%s %s started !!!' % (__PROGNAME__,__version__))
        app.run()
    
    t = threading.Thread(target=__init__)
    t.daemon = False
    t.start()
        
