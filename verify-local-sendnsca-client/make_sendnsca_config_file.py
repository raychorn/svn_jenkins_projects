import re, os, sys

from optparse import OptionParser

parser = OptionParser("usage: %prog [options]")
parser.add_option('-v', '--verbose', dest='verbose', help="verbose", action="store_true")
parser.add_option("-s", "--source", action="store", type="string", dest="source")
parser.add_option("-d", "--dest", action="store", type="string", dest="dest")
parser.add_option('-o', "--host", action="store", type="string", dest="host")
parser.add_option("-a", "--alias", action="store", type="string", dest="alias")
parser.add_option("-x", "--address", action="store", type="string", dest="address")
parser.add_option("-l", "--library", action="store", type="string", dest="library")

options, args = parser.parse_args()

source = None
if (options.source):
    source = options.source
print 'DEBUG: source=%s' % (source)

dest = None
if (options.dest):
    dest = options.dest
print 'DEBUG: dest=%s' % (dest)

host_name = None
if (options.host):
    host_name = options.host
print 'DEBUG: host_name=%s' % (host_name)

host_name_alias = None
if (options.alias):
    host_name_alias = options.alias
print 'DEBUG: host_name_alias=%s' % (host_name_alias)

host_address = None
if (options.address):
    host_address = options.address

    try:
        print 'DEBUG.1: host_address=%s' % (host_address)
        __regex_valid_ip_and_port__ = r"(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?):([0-9]{1,5})"
        __re1__ = re.compile(r"(-|--)(?P<option>\w*)=(?P<value>%s)"%(__regex_valid_ip_and_port__), re.MULTILINE)
        matches = __re1__.match(host_address)
        print 'DEBUG.2: matches=%s' % (matches)
        if (not matches):
            import socket
            host_address = socket.gethostbyname(host_address)
            print 'DEBUG.3: host_address=%s' % (host_address)
    except:
        host_address = None
print 'DEBUG: host_address=%s' % (host_address)

python_library = None
if (options.library):
    python_library = options.library

########################################################################################
python_library_path = os.path.abspath(python_library)
python_library_base = os.path.basename(python_library_path)

__has__ = False
for f in sys.path:
    if (f.find(python_library_base) > -1):
        __has__ = True
        break

print 'DEBUG: python_library_path=%s' % (python_library_path)
if (os.path.exists(python_library_path)):
    print 'DEBUG: __has__=%s' % (__has__)
    if (not __has__):
        sys.path.insert(0, python_library_path)
else:
    print 'WARNING: Cannot locate %s.' % (python_library_path)

print 'BEGIN: PYTHON_PATH'
for f in sys.path:
    print f
print 'END!!! PYTHON_PATH'

from vyperlogix.sockets import traceroute

__ip__ = '169.254.169.254' # this ip is required to determine the public and local IP addresses from Amazon...

__urls__ = [
    'http://%s/latest/meta-data/local-ipv4' % (__ip__),
    'http://%s/latest/meta-data/public-ipv4' % (__ip__)
]

__hops__ = {}

try:
    import urllib2
    for __url__ in __urls__:
        response = urllib2.urlopen(__url__)
        _default_ip = response.read()
        _ip = _default_ip
        __hops__[_ip] = traceroute.TraceRoute(_ip).hops
        num_hops = __hops__.get(_ip,None)
        print 'DEBUG.6: %s --> %s (%d hops)' % (__url__,_ip,num_hops)
        if (host_address and (_ip != host_address) and (num_hops == 0)):
            host_address = _ip
            print 'DEBUG.7: host_address --> %s' % (host_address)
            break
except:
    import getupnetips
    ifaces = [i for i in getupnetips.localifs() if (i[-1] != '127.0.0.1')]
    print 'DEBUG.5: ifaces=%s' % (ifaces)
    if (len(ifaces) > 0) and (len(ifaces[-1]) > 0):
        _ip = ifaces[-1][-1]
        __hops__[_ip] = traceroute.TraceRoute(_ip).hops
        num_hops = __hops__.get(_ip,None)
        print 'DEBUG.5a: _ip=%s (%d hops)' % (_ip,num_hops)
        host_address = _ip
        print 'DEBUG.8: host_address --> %s' % (host_address)
########################################################################################

try:
    host_name_with_underscores = host_name
    h = []
    for ch in host_name_with_underscores:
        if (str(ch).isalnum()):
            h.append(ch)
        else:
            h.append('_')
    host_name_with_underscores = ''.join(h)
except:
    host_name_with_underscores = None

if (host_name):
    print 'DEBUG: dest=%s' % (dest)
    dirname = os.path.dirname(dest)
    print 'DEBUG: dirname=%s' % (dirname)
    basename = os.path.basename(dest)
    print 'DEBUG: basename=%s' % (basename)
    toks0 = list(os.path.splitext(basename))
    ftype = toks0[-1]
    toks = toks0[0].split('_')
    retirees = toks[1:-1]
    if (len(retirees) > 0):
        del toks[1:-1]
        print 'DEBUG: host_name_with_underscores=%s' % (host_name_with_underscores)
    toks[0] = host_name_with_underscores
    toks0[0] = '_'.join(toks)
    basename = ''.join(toks0)
    dest = os.sep.join([dirname,basename])

print 'source --> %s' % (source)
print 'dest --> %s' % (dest)
print 'host_name --> %s' % (host_name)
print 'host_name_alias --> %s' % (host_name_alias)
print 'host_address --> %s' % (host_address)
print 'host_name_with_underscores --> %s' % (host_name_with_underscores)

fpath = os.sep.join([os.path.dirname(source),'host_address'])
print 'host_address (file) --> %s' % (fpath)
fOut = open(fpath, mode='w')
print >> fOut, '%s' % (host_address)
fOut.flush()
fOut.close()


__re__ = re.compile(r"\{\{(?P<name>.*)\}\}", re.DOTALL | re.MULTILINE)

'''
####################################################################
##
## {{host_name}}
## {{host_name_alias}}
## {{host_address}}
## {{host_name_with_underscores}}
##
#####################################################################

'''
replacements = {}

replacements['{{host_name}}'] = host_name
replacements['{{host_name_alias}}'] = host_name_alias
replacements['{{host_address}}'] = host_address
replacements['{{host_name_with_underscores}}'] = host_name_with_underscores

if (os.path.exists(source)):
    fIn = open(source, 'r')
    lines = fIn.readlines()
    fIn.close()

    issue_count = 0
    
    fOut = open(dest, 'w')
    for l in lines:
        s = str(l).rstrip()
        for k,v in replacements.iteritems():
            if (k and v):
                s = s.replace(k, v)
        print >> fOut, s
        match = __re__.search(s)
        if (match):
            issue_count += 1
    fOut.flush()
    fOut.close()
    
    if (issue_count > 0):
        sys.exit(1)

else:
    print >> sys.stderr, 'WARNING: Cannot find the source in "%s".' % (source)
