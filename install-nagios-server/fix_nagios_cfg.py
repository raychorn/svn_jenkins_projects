import re, os, sys

__re__ = re.compile("temp_path=(?P<temp_path>.*)", re.DOTALL | re.MULTILINE)

def find_nagios_cfg(top,target):
    print 'DEBUG: top=%s, target=%s' % (top,target)
    for folder,dirs,files in os.walk(top):
        if (any([f == target for f in files])):
            return os.sep.join([folder,target])
    print 'DEBUG: None found !!!'
    return None

__top__ = '/usr'
fpath = find_nagios_cfg(__top__, 'nagios.cfg')
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
    
    fOut = open(fpath+'.new', mode='w')
    for l in lines:
        matches = __re__.search(l)
        if (matches):
            temp_path = matches.groupdict().get('temp_path',None)
            if (temp_path):
                l = l.replace(temp_path,__temp_path__)
        print >> fOut, str(l).rstrip()
    fOut.flush()
    fOut.close()
    
    os.remove(fpath)
    os.rename(fOut.name,fpath)

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
