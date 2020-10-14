import re
import os, sys
from __exceptions__ import formattedException

isUsingWindows = (sys.platform.lower().find('win') > -1) and (os.name.lower() == 'nt')
isUsingMacOSX = (sys.platform.lower().find('darwin') > -1) and (os.name.find('posix') > -1) and (not isUsingWindows)
isUsingLinux = (sys.platform.lower().find('linux') > -1) and (os.name.find('posix') > -1) and (not isUsingWindows) and (not isUsingMacOSX)

def isString(s):
    return (isinstance(s,str)) or (isinstance(s,unicode))

isStringValid = lambda s:(s) and isString(s) and (len(s) > 0)

def isBoolean(s):
    return (isinstance(s,bool))

def isBooleanString(s):
    d = {'True': True, 'False': False,}
    t = str(s).lower().capitalize()
    if (isString(t) and (t in d.keys())):
	return d[t]
    return False

def isInteger(s):
    return (isinstance(s,int))

def isFloat(s):
    return (isinstance(s,float))

def isDate(s):
    from datetime import date
    return isinstance(s,date)

def isSimpleDict(s):
    return (isinstance(s,dict))

def isDict(s):
    _has_key = False
    try:
	_has_key = callable(s.has_key)
    except:
	_has_key = False
    return (isSimpleDict(s)) or (_has_key)

def isList(obj):
    try:
        return callable(obj.append)
    except:
        pass
    return False

def isTuple(obj):
    try:
	if (len(obj) == 0):
	    obj += (1)
	if (len(obj) > 0):
	    obj[0] = obj[0]
    except:
        return True
    return False

def isIterable(obj):
    try: 
        return hasattr(obj,'__iter__')
    except TypeError: 
        return False

def md5(plain):
    import hashlib
    m = hashlib.md5()
    m.update(plain)
    return m.hexdigest()

def handle_services(cfgname,payload,logger):
    __re2__ = re.compile("\Ahost[0-9]*_")
    __re3__ = re.compile("\Aservice[0-9]*_")
    __re4__ = re.compile("\Acommand[0-9]*_")
    __services__ = []
    __status__ = ''
    if (cfgname):
	logger.debug('DEBUG.1: payload.keys()=%s' % (payload.keys()))

	items = [k for k in payload.keys() if (__re2__.search(k))]
	logger.debug('DEBUG.1: items=%s' % (items))
	hosts = SmartObject()
	for item in items:
	    toks = item.split('_')
	    if (hosts[toks[0]] is None):
		hosts[toks[0]] = SmartObject()
	    hosts[toks[0]]['_'.join(toks[1:])] = payload[item]
	logger.debug('DEBUG.2: hosts=%s' % (hosts.__dict__))

	items = [k for k in payload.keys() if (__re4__.search(k))]
	logger.debug('DEBUG.4: items=%s' % (items))
	commands = SmartObject()
	for item in items:
	    toks = item.split('_')
	    if (commands[toks[0]] is None):
		commands[toks[0]] = SmartObject()
	    commands[toks[0]]['_'.join(toks[1:])] = payload[item]
	logger.debug('DEBUG.5: commands=%s' % (commands.__dict__))

	items = [k for k in payload.keys() if (__re3__.search(k))]
	logger.debug('DEBUG.3: items=%s' % (items))
	services = SmartObject()
	toks = None
	count = 0
	for item in items:
	    toks = item.split('_')
	    if (services[toks[0]] is None):
		services[toks[0]] = SmartObject()
		count += 1
	    services[toks[0]]['_'.join(toks[1:])] = payload[item]
	if (isList(payload.partition_names)):
	    logger.debug('DEBUG.4.0: payload.partition_names=%s' % (payload.partition_names))
	    for pname in payload.partition_names:
		logger.debug('DEBUG.4.0.1: pname=%s' % (pname))
		sname = 'service%s' % (count+1)
		if (services[sname] is None):
		    services[sname] = SmartObject()
		first_host = None
		for k,v in hosts.__dict__.iteritems():
		    logger.debug('DEBUG.4.1: %s=%s [%s]' % (k,v,(k not in ['__dict__'])))
		    if (k not in ['__dict__']):
			first_host = v
			logger.debug('DEBUG.4.1.1: first_host=%s' % (first_host))
			break
		first_command = None
		for k,v in commands.__dict__.iteritems():
		    logger.debug('DEBUG.4.2: %s=%s [%s]' % (k,v,(k not in ['__dict__'])))
		    if (k not in ['__dict__']):
			first_command = v
			logger.debug('DEBUG.4.2.1: first_command=%s' % (first_command))
			break
		services[sname]["use"] = "generic-service"
		services[sname]["host_name"] = first_host['host_name'] if (first_host) else 'UNKNOWN'
		services[sname]["service_description"] = pname
		services[sname]["active_checks_enabled"] = "0"
		services[sname]["passive_checks_enabled"] = "1"
		services[sname]["check_command"] = first_command['command_name'] if (first_command) else 'dummy_command'
		count += 1
	    logger.debug('DEBUG.4.3: services[%s]=%s' % (sname,services[sname]))
	logger.debug('DEBUG.4: services=%s' % (services.__dict__))

	if (len(items) > 0):
	    logger.debug('DEBUG: BEGIN:')
	    preamble = 'define %s{'
	    fOut = open(cfgname,'w')
	    try:
		def emit_object_using(bucket,name,pre):
		    longest = -1
		    for k,v in bucket.__dict__.iteritems():
			logger.debug('DEBUG (longest.1): %s=%s' % (k,v))
			if (k not in ['__dict__']):
			    try:
				for kk,vv in v.__dict__.iteritems():
				    if (kk not in ['__dict__']):
					longest = max(longest,len(kk))
					logger.debug('DEBUG (longest.2): longest=%s' % (longest))
			    except:
				pass
		    longest += 10
		    logger.debug('DEBUG (longest.3): longest=%s' % (longest))
		    for k,v in iter(sorted(bucket.__dict__.iteritems())):
			logger.debug('DEBUG.1: %s=%s' % (k,v))
			if (k not in ['__dict__']):
			    try:
				logger.debug('DEBUG.2: %s=%s' % (k,v))
				logger.debug('DEBUG.2.1: %s, %s' % (pre,name))
				fOut.write('%s\n' % (pre % (name)))
				for kk,vv in v.__dict__.iteritems():
				    logger.debug('DEBUG.3: (%s)' % ((kk not in ['__dict__'])))
				    if (kk not in ['__dict__']):
					fOut.write('\t%s%s%s\n' % (kk,' '*(longest-len(kk)),vv))
				fOut.write('}\n\n')
			    except Exception, ex:
				logger.exception('EXCEPTION: %s' % (formattedException(details=ex)))
		emit_object_using(hosts, 'host', preamble)
		emit_object_using(commands, 'command', preamble)
		emit_object_using(services, 'service', preamble)
	    except Exception, ex:
		logger.exception('EXCEPTION: %s' % (formattedException(details=ex)))
	    logger.debug('DEBUG: END !!!')
	    logger.debug('DEBUG: fOut=%s' % (fOut.name))
	    fOut.flush()
	    fOut.close()
	else:
	    logger.error('ERROR: Cannot handle_services unless services have been defined in payload.')
    else:
	logger.error('ERROR: Cannot handle_services with cfgname of "%s".' % (cfgname))
    return __status__

def handle_disk_services(cfgname,payload,logger):
    __re1__ = re.compile(r"define\s*service.*\{")
    __re2__ = re.compile(r"service_description\s*DISK")
    __re3__ = re.compile("service[0-9]*_")
    __services__ = []
    __status__ = ''
    if (cfgname) and (os.path.exists(cfgname)):
	logger.debug('DEBUG.1: payload.keys()=%s' % (payload.keys()))
	items = [k for k in payload.keys() if (__re3__.search(k))]
	logger.debug('DEBUG.1: items=%s' % (items))
	services = SmartObject()
	for item in items:
	    toks = item.split('_')
	    if (services[toks[0]] is None):
		services[toks[0]] = SmartObject()
	    services[toks[0]]['_'.join(toks[1:])] = payload[item]
	logger.debug('DEBUG.1a: services=%s' % (services.__dict__))
	if (len(items) > 0):
	    __matches__ = False

	    def collecting(aLine,m,lineNum):
		__service__.append(SmartObject(args={'linenum':lineNum,'content':aLine}))
		logger.debug('DEBUG.2: collecting=%s' % (len(__service__)))
		if (aLine.find('}') > -1):
		    m = False
		    logger.debug('DEBUG.3: __matches__=%s' % (__matches__))
		return m

	    fIn = open(cfgname)
	    try:
		lines = fIn.readlines()
		__service__ = []
		matches2 = None
		line_num = 0
		for l in lines:
		    line_num += 1
		    logger.debug('DEBUG.4: l=%s' % (l))
		    if (__matches__):
			logger.debug('DEBUG.5: matches2=%s' % (matches2))
			if (matches2 is None):
			    matches2 = __re2__.search(l)
			    logger.debug('DEBUG.6: matches2=%s' % (matches2))
			__matches__ = collecting(l,__matches__,line_num)
		    else:
			matches1 = __re1__.search(l)
			logger.debug('DEBUG.7: matches1=%s' % (matches1))
			if (matches1):
			    logger.debug('DEBUG.8: matches2=%s' % (matches2))
			    if (matches2 is not None):
				__services__.append(__service__)
				matches2 = None
			    __service__ = []
			    __matches__ = True
			    logger.debug('DEBUG.9: __matches__=%s' % (__matches__))
			    __matches__ = collecting(l,__matches__,line_num)
	    except Exception, ex:
		logger.exception('EXCEPTION: %s' % (formattedException(details=ex)))
	    fIn.close()
	    __status__ = 'Found %s service%s in %s to be replaced by %s service%s from payload.' % (len(__services__),'s' if (len(__services__) > 1) else '',cfgname,len(services.__dict__),'s' if (len(services.__dict__) > 1) else '')
	    logger.debug('DEBUG: %s' % (__status__))
	    if (len(__services__) > 0):
		cfgname_new = cfgname+'.new'
		for svc in __services__:
		    l_begin = svc[0].linenum
		    l_end = svc[-1].linenum
		    preamble = ''
		    assert l_begin < l_end, 'ERROR.1: Check your logic, sir.'
		    logger.debug('DEBUG: BEGIN:')
		    fIn = open(cfgname)
		    fOut = open(cfgname_new,'w')
		    for i in xrange(0,l_begin):
			l = fIn.readline()
			if (i < l_begin):
			    preamble = l
			    fOut.write(l)
		    try:
			if (0):
			    for i in xrange(l_begin,l_end):
				l = fIn.readline()
				logger.debug('DEBUG: SKIPPING: %s' % (l))
			    for item in svc:
				#assert l == item.content, 'ERROR.2: Check your logic, please.  Expected (%s) got (%s).' % (item.content,l)
				logger.debug('DEBUG: %s' % (item.__dict__))
				#l = fIn.readline()  # toss this line away
				fOut.write(item.content)
			if (1):
			    longest = -1
			    for k,v in services.__dict__.iteritems():
				logger.debug('DEBUG (longest.1): %s=%s' % (k,v))
				if (k not in ['__dict__']):
				    try:
					for kk,vv in v.__dict__.iteritems():
					    if (kk not in ['__dict__']):
						longest = max(longest,len(kk))
						logger.debug('DEBUG (longest.2): longest=%s' % (longest))
				    except:
					pass
			    longest += 10
			    logger.debug('DEBUG (longest.3): longest=%s' % (longest))
			    for k,v in iter(sorted(services.__dict__.iteritems())):
				logger.debug('DEBUG: %s=%s' % (k,v))
				l = fIn.readline() # toss this line away
				if (k not in ['__dict__']):
				    try:
					for kk,vv in v.__dict__.iteritems():
					    if (kk not in ['__dict__']):
						fOut.write('\t%s%s%s\n' % (kk,' '*(longest-len(kk)),vv))
					fOut.write('}\n\n')
					fOut.write('%s' % (preamble))
				    except:
					pass
			while (1):
			    l = fIn.readline()
			    if (not l):
				break
			    fOut.write(l)
		    except Exception, ex:
			logger.exception('EXCEPTION: %s' % (formattedException(details=ex)))
		    logger.debug('DEBUG: END !!!')
		    logger.debug('DEBUG: fIn=%s, fOut=%s' % (fIn.name,fOut.name))
		    fIn.close()
		    fOut.flush()
		    fOut.close()
	else:
	    logger.error('ERROR: Cannot handle_services unless services have been defined in payload.')
    else:
	logger.error('ERROR: Cannot handle_services with cfgname of "%s".' % (cfgname))
    return __status__

def typeClassName(obj):
    try:
        sObj = str(obj.__class__)
    except AttributeError:
        sObj = str(obj)
    except:
        return typeName(obj)
    toks = sObj.replace('<','').replace('>','').replace("'",'').replace('object at','object_at').split()
    if (len([t for t in toks if (t == 'object_at')]) > 0):
	pass
        return toks[-1]
    return toks[0]

def walk(top, topdown=True, onerror=None, rejecting_re=None):
    isRejectingRe = typeClassName(rejecting_re) == '_sre.SRE_Pattern'

    try:
        names = [n for n in os.listdir(top) if (not isRejectingRe) or (isRejectingRe and not rejecting_re.search(n))]
    except os.error, err:
        if onerror is not None:
            onerror(err)
        return

    dirs, nondirs = [], []
    for name in names:
        if os.path.isdir(os.path.join(top, name)):
            dirs.append(name)
        else:
            nondirs.append(name)

    if topdown:
        yield top, dirs, nondirs
    for name in dirs:
        path = os.path.join(top, name)
        if not os.path.islink(path):
            for x in walk(path, topdown, onerror, rejecting_re):
                yield x
    if not topdown:
        yield top, dirs, nondirs

def shellexecute(cmd):
    results = None
    if (isUsingLinux):
	try:
	    infile, outfile, errfile = os.popen3(cmd)
	    stdout_lines = outfile.readlines()
	    stderr_lines = errfile.readlines()
	    results = stdout_lines + stderr_lines
	except Exception, ex:
	    results = formattedException(details=ex)
    return results

class SmartObject(object):
    def __init__(self,args={}):
        '''Populate from a dict object.'''
        self.__dict__ = {}
        self.fromDict(args)
    
    def fromDict(self, args):
        try:
            __iter__ = args.iteritems()
        except:
            __iter__ = []
        for ak,av in __iter__:
            try:
                for k,v in av.iteritems():
                    self.__dict__['%s_%s' % (ak,k)] = v
            except:
                self.__dict__[ak] = av
    
    def __str__(self):
        ascii_only = lambda s:''.join([ch for ch in s if (ord(ch) >= 32) and (ord(ch) <= 127)])
        _vars = []
        for k,v in self.__dict__.iteritems():
            _vars.append('%s="%s"' % (k,ascii_only(v) if (isinstance(v,str)) else str(v)))
        return '(%s) %s' % (str(self.__class__),', '.join(_vars))
    
    def keys(self):
        return self.__dict__.keys()
    
    def has_key(self,key):
        return self.__dict__.has_key(key)
    
    def iteritems(self):
        return [(k,v) for k,v in self.__dict__.iteritems() if (k != '__dict__')]
    
    def __getitem__(self, name):
        return self.__getattr__(name)
        
    def __setitem__(self,name,value):
        self.__setattr__(name,value)
    
    def __getattr__(self, name):
        if (self.__dict__.has_key(name)):
            return self.__dict__[name]
        else:
            return None
        
    def __setattr__(self, name, value):
        __is__ = False
        try:
            __is__ = (value == None)
        except:
            pass
        if (__is__) and (self.__dict__.has_key(name)):
            del self.__dict__[name]
        else:
            self.__dict__[name] = value
        

if (__name__ == '__main__'):
    print md5('plaintext')
