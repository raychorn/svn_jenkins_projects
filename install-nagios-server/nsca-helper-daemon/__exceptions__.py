def __callersName__():
    """ get name of caller of a function """
    import sys
    return sys._getframe(2).f_code.co_name

def isInteger(s):
    return (isinstance(s,int))

def formattedException(details='',callersName=None,depth=None,delims='\n'):
    callersName = callersName if (callersName) else __callersName__()
    import sys, traceback
    exc_info = sys.exc_info()
    stack = traceback.format_exception(*exc_info)
    stack = stack if ( (depth is None) or (not isInteger(depth)) ) else stack[0:depth]
    try:
	info_string = delims.join(stack)
    except:
	info_string = '\n'.join(stack)
    return '(' + callersName + ') :: "' + str(details) + '". ' + info_string
