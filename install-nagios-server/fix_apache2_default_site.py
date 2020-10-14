import re, os, sys
import socket

from dns import resolver,reversename

__re__ = re.compile(r"<VirtualHost \*:(?P<port>[0-9]*)>", re.MULTILINE)
__re2__ = re.compile(r"ServerName\s(?P<ServerName>.*)", re.MULTILINE)

server_ip = None
ServerName = sys.argv[1] if (len(sys.argv) > 1) else None
if (ServerName):
    server_ip = socket.gethostbyaddr(ServerName)[-1][0]

print 'ServerName is "%s" with ip of %s.' % (ServerName,server_ip)

fpath = '/etc/apache2/sites-available/default'
if (os.path.exists(fpath)):
    fIn = open(fpath, 'r')
    lines = fIn.readlines()
    fIn.close()

    __is__ = False
    __is_servername_valid__ = False
    __is_ServerName_directive_present__ = False

    __pos__ = -1
    i = 0
    for l in lines:
        matches = __re__.search(l)
        if (matches):
            __pos__ = i
            __is__ = True
        matches = __re2__.search(l)
        if (matches):
            __is_ServerName_directive_present__ = True
        i += 1

    if (__is__):
        __ip__ = '169.254.169.254'

        __urlLocal__ = 'http://%s/latest/meta-data/local-ipv4' % (__ip__)
        __urlPublic__ = 'http://%s/latest/meta-data/public-ipv4' % (__ip__)

        __urls__ = [__urlLocal__,__urlPublic__]

        import urllib2
        for __url__ in __urls__:
            response = urllib2.urlopen(__url__)
            __ip__ = response.read()
            __addr__ = reversename.from_address(__ip__)
            __dns__ = str(resolver.query(__addr__,"PTR")[0])
            if (__ip__ == server_ip):
                __is_servername_valid__ = True
            print '%s --> %s (%s)' % (__url__,__ip__,__dns__)
    else:
        print >> sys.stderr, 'WARNING: Cannot verify "%s" as a VirtualHost.' % (fpath)

    __directive__ = '\tServerName %s' % (ServerName)
    print '(+++) __is_servername_valid__=%s' % (__is_servername_valid__)
    if (__is_servername_valid__):
        print '(+++) __is_ServerName_directive_present__=%s' % (__is_ServerName_directive_present__)
        print '(+++) __pos__=%s' % (__pos__)
        if (not __is_ServerName_directive_present__) and (__pos__ > -1):
            lines.insert(__pos__+1,__directive__)

        __found__ = False
        fOut = open(fpath+'.new', 'w')
        for l in lines:
            matches = __re2__.search(l)
            if (matches):
                print '%s (%s) --> %s' % (matches,matches.start(),l)
                _l_ = __directive__
                l = l[0:matches.start()] + _l_
                print 'FOUND: %s' % (l)
                __found__ = True
            print >> fOut, str(l).rstrip()
        fOut.flush()
        fOut.close()

        os.remove(fpath)
        os.rename(fOut.name,fpath)
    else:
        print >> sys.stderr, 'WARNING: Cannot verify ServerName (%s) for this physical server (%s).' % (ServerName,server_ip)

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
