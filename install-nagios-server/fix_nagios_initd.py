import re, os, sys

__re1__ = re.compile(r"killproc\s\-p.*")
fname = "/usr/sbin/service" # do not change this line...
__re2__ = re.compile("(?P<usr>[/usr]*)/sbin/service", re.DOTALL | re.MULTILINE)

__re3__ = re.compile("^### BEGIN INIT INFO$", re.DOTALL | re.MULTILINE)
__re4__ = re.compile("^### END INIT INFO$", re.DOTALL | re.MULTILINE)

def find_real_file(top,target):
    print 'DEBUG: top=%s, target=%s' % (top,target)
    for folder,dirs,files in os.walk(top):
        if (any([f == target for f in files])):
            return os.sep.join([folder,target])
    print 'DEBUG: None found !!!'
    return None

fpath = '/etc/init.d/nagios'
if (os.path.exists(fpath)):
    fIn = open(fpath, 'r')
    lines = fIn.readlines()
    fIn.close()

    toks = fname.split(os.sep)
    print 'DEBUG: toks=%s' % (toks)
    service = find_real_file('/'+[t for t in toks if (len(t) > 0)][0], toks[-1])
    print 'DEBUG: service=%s' % (service)
    
    __is__ = False
    __header__ = []
    
    fOut = open(fpath+'.new', 'w')
    for l in lines:
        matches1 = __re1__.search(l)
        matches2 = __re2__.search(l)
        matches3 = __re3__.search(l)
        matches4 = __re4__.search(l)
        if (matches1):
            print '%s (%s) --> %s' % (matches1,matches1.start(),l)
            _l_ = 'kill -9 $(cat ${pidfile})'
            l = l[0:matches1.start()] + _l_
            print 'FOUND (1): %s' % (l)
        elif (matches2 and service):
            print '%s (%s) --> %s' % (matches2,matches2.start(),l)
            c = [t for t in l]
            print '(1) DEBUG: c=%s' % (c)
            del c[matches2.start():matches2.end()]
            print '(2) DEBUG: c=%s' % (c)
            cbegin = c[0:matches2.start()]
            cend = c[1:]
            print '(3) DEBUG: cbegin=%s' % (cbegin)
            print '(4) DEBUG: cend=%s' % (cend)
            cc = cbegin + [t for t in service] + cend
            print '(5) DEBUG: cc=%s' % (cc)
            _l_ = ''.join(cc)
            print 'FOUND (2): "%s" --> "%s"' % (l,_l_)
            l = _l_
        elif (matches3 and (not __is__)):
            __is__ = True
            __header__.append(l)
        elif ((not matches3) and (not matches4) and __is__):
            __header__.append(l)
        elif (matches4 and __is__):
            __is__ = False
            #__header__.append(l)

            __new_headers__ = []

            items = {}
            other_items = []
            for h in __header__[1:]:
                toks = h.split(':')
                if (len(toks) == 2):
                    items[toks[0]] = toks[-1]
                else:
                    other_items.append(h)
            __new_headers__.append(__header__[0])
            for k,v in items.iteritems():
                __new_headers__.append('%s:%s' % (k,v))
            for h in other_items:
                __new_headers__.append(h)
            __new_headers__.append(__header__[-1])

            print 'DEBUG: BEGIN-new-headers'
            for h in __new_headers__:
                print h
                print >> fOut, str(h).rstrip()
            print 'DEBUG: END-new-headers'
        if (not __is__):
            print >> fOut, str(l).rstrip()
    fOut.flush()
    fOut.close()

    os.remove(fpath)
    os.rename(fOut.name,fpath)

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
