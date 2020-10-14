import re, os, sys

isBeingDebugged = False if (not os.environ.has_key('WINGDB_ACTIVE')) else int(os.environ['WINGDB_ACTIVE']) == 1

__re__ = re.compile("(?P<commented>(#|))cfg_file=(?P<cfg_file>.*)", re.DOTALL | re.MULTILINE)

def find_nagios_cfg(top,target):
    print 'DEBUG: top=%s, target=%s' % (top,target)
    for folder,dirs,files in os.walk(top):
        if (any([f == target for f in files])):
            return os.sep.join([folder,target])
    print 'DEBUG: None found !!!'
    return None

__top__ = '/usr' if (not isBeingDebugged) else r'J:\@11.1'
fpath = find_nagios_cfg(__top__, 'nagios.cfg')
fdest = sys.argv[-1]
print 'INFO(1): nagios.cfg is %s' % (fpath)

fdest_dir = os.path.dirname(fdest)
fdest_base = os.path.basename(fdest)
toks = fdest_base.split('_')
retirees = toks[1:-1]
if (len(retirees) > 0):
    del toks[1:-1]
fdest_base = '_'.join(toks)
fdest = os.sep.join([fdest_dir,fdest_base])

print 'INFO(2): fdest is %s' % (fdest)

print 'INFO: nagios.cfg is %s' % (fpath)
if (os.path.exists(fdest)):
    if (os.path.exists(fpath)):
        fIn = open(fpath, 'r')
        lines = fIn.readlines()
        fIn.close()
    
        __temp_path__ = os.path.dirname(fpath)
        toks = __temp_path__.split(os.sep)
        if (len(toks) > 1):
            del toks[-1]
            toks.append('tmp')
            __temp_path__ = os.sep.join(toks)
            if (not os.path.exists(__temp_path__)):
                os.mkdir(__temp_path__)
    
        __lines__ = []
        
        __matches__ = []
        
        first_time_used = -1
        count = 0
        __was__ = False
        for l in lines:
            __is__ = False
            matches = __re__.search(l)
            if (matches):
                print 'FOUND: %s' % (matches.groupdict())
                is_commented = len(matches.groupdict().get('commented','')) > 0
                if (not is_commented):
                    cfg_file = matches.groupdict().get('cfg_file',None)
                    if (cfg_file):
                        cfg_file = str(cfg_file).rstrip()
                        if (cfg_file == fdest):
                            __was__ = True
                        __matches__.append(matches.groupdict())
                    if (first_time_used == -1):
                        first_time_used = count
                else: # is a match but is commented so use the line.
                    __is__ = True
            else: # not a match so use the line.
                __is__ = True
            if (__is__):
                __lines__.append(str(l).rstrip())
            count += 1
            
        i = len(__lines__)-1
        while (i > 2):
            if (len(__lines__[i]) == 0) and (len(__lines__[i-1]) == 0) and (len(__lines__[i-2]) == 0):
                del __lines__[i]
            i -= 1
            
        if (not __was__):
            d = {'commented': '', 'cfg_file': fdest}
            print 'APPEND: %s' % (d)
            __matches__.append(d)
        
        fOut = open(fpath+'.new', mode='w')
        count = 0
        for l in __lines__:
            print >> fOut, str(l).rstrip()
            if (count == first_time_used):
                for m in __matches__:
                    is_commented = len(m.get('commented','')) > 0
                    comment = ''
                    if (is_commented):
                        comment = '#'
                    cfg_file = m.get('cfg_file',None)
                    print >> fOut, '%s%s' % (comment,'cfg_file=%s' % (cfg_file))
            count += 1
        fOut.flush()
        fOut.close()
        
        os.remove(fpath)
        os.rename(fOut.name,fpath)
    
    else:
        print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
else:
    print >> sys.stderr, 'WARNING: Cannot find dest config file "%s"; make sure this file is mentioned on the command line as the 1st argument.' % (fdest)
