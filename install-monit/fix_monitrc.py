import re, os, sys
import socket

__ip__ = '169.254.169.254' # this ip is required to determine the public and local IP addresses from Amazon...

__urls__ = [
    'http://%s/latest/meta-data/local-ipv4' % (__ip__),
    'http://%s/latest/meta-data/public-ipv4' % (__ip__)
]

__default_port__ = 2812
__default_mailfrom__ = 'support@vyperlogix.com'
__default_admin__ = 'admin'
__default_password__ = 'peekab00'
__default_mailserver__ = 'smtp.mailgun.org'
__default_mailserverport__ = 587
__default_mailserveruser__ = 'support@vyperlogix.com'
__default_mailserveruserpassword__ = 'peekab00'

from optparse import OptionParser

if (len(sys.argv) == 1):
    sys.argv.insert(len(sys.argv), '-h')

parser = OptionParser("usage: %prog [options]")
parser.add_option('-v', '--verbose', dest='verbose', help="verbose", action="store_true")
parser.add_option("-p", "--port", action="store", type="string", help="Monit Port Number.", dest="port")
parser.add_option("-m", "--mailfrom", action="store", type="string", help="Monit Mail From address.", dest="mailfrom")
parser.add_option("-a", "--admin", action="store", type="string", help="Monit Admin User Name.", dest="admin")
parser.add_option("-w", "--password", action="store", type="string", help="Monit Admin Password.", dest="password")
parser.add_option("-s", "--mailserver", action="store", type="string", help="Monit Mail Server domain or IP address.", dest="mailserver")
parser.add_option("-o", "--mailserverport", action="store", type="string", help="Monit Mail Server Port.", dest="mailserverport")
parser.add_option("-u", "--mailserveruser", action="store", type="string", help="Monit Mail Server User.", dest="mailserveruser")
parser.add_option("-d", "--mailserveruserpassword", action="store", type="string", help="Monit Mail Server User Password.", dest="mailserveruserpassword")

options, args = parser.parse_args()

_isVerbose = False
if (options.verbose):
    _isVerbose = True

__port__ = __default_port__
if (options.port):
    __port__ = options.port
    
print 'DEBUG: options.port=%s' % (options.port)

__mailfrom__ = __default_mailfrom__
if (options.mailfrom):
    __mailfrom__ = options.mailfrom
    
print 'DEBUG: options.mailfrom=%s' % (options.mailfrom)

__admin__ = __default_admin__
if (options.admin):
    __admin__ = options.admin
    
print 'DEBUG: options.admin=%s' % (options.admin)

__password__ = __default_password__
if (options.password):
    __password__ = options.password
    
print 'DEBUG: options.password=%s' % (options.password)

__mailserver__ = __default_mailserver__
if (options.mailserver):
    __mailserver__ = options.mailserver
    
print 'DEBUG: options.mailserver=%s' % (options.mailserver)

__mailserverport__ = __default_mailserverport__
if (options.mailserverport):
    __mailserverport__ = options.mailserverport
    
print 'DEBUG: options.mailserverport=%s' % (options.mailserverport)

__mailserveruser__ = __default_mailserveruser__
if (options.mailserveruser):
    __mailserveruser__ = options.mailserveruser
    
print 'DEBUG: options.mailserveruser=%s' % (options.mailserveruser)

__mailserveruserpassword__ = __default_mailserveruserpassword__
if (options.mailserveruserpassword):
    __mailserveruserpassword__ = options.mailserveruserpassword
    
print 'DEBUG: options.mailserveruserpassword=%s' % (options.mailserveruserpassword)

ip_addresses = []

try:
    import urllib2
    for __url__ in __urls__:
        response = urllib2.urlopen(__url__)
        _default_ip = response.read()
        ip_addresses.append(_default_ip)
except:
    print 'EXCEPTION: Cannot determine the IP address for this host.'

__choices__ = {}

__choices__['ip_addresses'] = {
    '__re__':re.compile(r"\{\{VMIP\}\}", re.DOTALL | re.MULTILINE),
    'value':', '.join(ip_addresses)
}

__choices__['port'] = {
    '__re__':re.compile(r"\{\{PORT\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__port__)
}

__choices__['mailfrom'] = {
    '__re__':re.compile(r"\{\{MAILFROM\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__mailfrom__)
}

__choices__['admin'] = {
    '__re__':re.compile(r"\{\{ADMIN\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__admin__)
}

__choices__['password'] = {
    '__re__':re.compile(r"\{\{PASSWORD\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__password__)
}

__choices__['mailserver'] = {
    '__re__':re.compile(r"\{\{MAILSERVER\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__mailserver__)
}

__choices__['mailserverport'] = {
    '__re__':re.compile(r"\{\{MAILSERVERPORT\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__mailserverport__)
}

__choices__['mailserveruser'] = {
    '__re__':re.compile(r"\{\{MAILSERVERUSER\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__mailserveruser__)
}

__choices__['mailserveruserpassword'] = {
    '__re__':re.compile(r"\{\{MAILSERVERUSERPASSWORD\}\}", re.DOTALL | re.MULTILINE),
    'value':'%s' % (__mailserveruserpassword__)
}

fpath = '/etc/monit/monitrc'
#fpath = r"J:\@Vyper Logix Corp\@Projects\jenkins\install-monit\monitrc.mine"
if (os.path.exists(fpath)):
    fIn = open(fpath, 'r')
    lines = fIn.readlines()
    fIn.close()
    
    paste_into = lambda aLine,matches,sometext:aLine[0:matches.start()] + sometext + aLine[matches.end():]

    fOut = open(fpath+'.new', 'w')
    for l in lines:
        for k,aChoice in __choices__.iteritems():
            #print 'DEBUG: k=%s, aChoice=%s' % (k,aChoice)
            __re__ = aChoice.get('__re__',None)
            if (__re__):
                matches = __re__.search(l)
                if (matches):
                    print '%s (%s) --> %s' % (matches,matches.start(),l)
                    _l_ = aChoice.get('value','')
                    l = paste_into(l,matches,_l_)
                    print 'FOUND: %s' % (l)
        #matches1 = __re1__.search(l)
        #if (matches1):
            #print '%s (%s) --> %s' % (matches1,matches1.start(),l)
            #_l_ = ', '.join(ip_addresses)
            #l = paste_into(l,matches1,_l_)
            #print 'FOUND: %s' % (l)
        #matches2 = __re2__.search(l)
        #if (matches2):
            #print '%s (%s) --> %s' % (matches2,matches2.start(),l)
            #_l_ = '%s' % (__port__)
            #l = paste_into(l,matches2,_l_)
            #print 'FOUND: %s' % (l)
        #matches3 = __re3__.search(l)
        #if (matches3):
            #print '%s (%s) --> %s' % (matches3,matches3.start(),l)
            #_l_ = '%s' % (__mailfrom__)
            #l = paste_into(l,matches3,_l_)
            #print 'FOUND: %s' % (l)
        #matches4 = __re4__.search(l)
        #if (matches4):
            #print '%s (%s) --> %s' % (matches4,matches4.start(),l)
            #_l_ = '%s' % (__admin__)
            #l = paste_into(l,matches4,_l_)
            #print 'FOUND: %s' % (l)
        #matches5 = __re5__.search(l)
        #if (matches5):
            #print '%s (%s) --> %s' % (matches5,matches5.start(),l)
            #_l_ = '%s' % (__password__)
            #l = paste_into(l,matches5,_l_)
            #print 'FOUND: %s' % (l)
        #matches6 = __re6__.search(l)
        #if (matches6):
            #print '%s (%s) --> %s' % (matches6,matches6.start(),l)
            #_l_ = '%s' % (__mailserver__)
            #l = paste_into(l,matches6,_l_)
            #print 'FOUND: %s' % (l)
        print >> fOut, str(l).rstrip()
    fOut.flush()
    fOut.close()

    os.remove(fpath)
    os.rename(fOut.name,fpath)

else:
    print >> sys.stderr, 'WARNING: Cannot find "%s".' % (fpath)
