import json
f = open("inp.txt")
inp = f.readlines()
f.close()
#print(inp)
parsD = []

def searchPart(listIn, searchT):
    for i, elem in enumerate(listIn):
        if searchT in elem:
            return i

curEl = -1
global i
for i in range(len(inp)):
    curD = {}
    curL = inp[i]
    if curL.split()[0] == "signal" or curL.split()[0] == "method":
        curD["mainStr"] = curL
        spltMain = curL.split()
        dicKeys = [
            'type',
            'sender',
            'dest',
            'serial',
            'interface',
            'member',
            'path'
            ]
        mainStruct = dict.fromkeys(dicKeys)
        for el in dicKeys:
            if el == "type":
                if spltMain[0] == "signal": 
                    mainStruct["type"] = "signal"
                elif spltMain[0] == "method":
                    mainStruct["type"] = "method call"
            elif el == 'dest':
                res = spltMain[searchPart(spltMain,el)].split('=')
                if res[1] == '(null':
                    mainStruct['dest'] = None
                else:
                    mainStruct['dest'] = res[1]
            else:
                res = spltMain[searchPart(spltMain,el)].split('=')
                mainStruct[el] = res[1].replace(';','')
        #print(mainStruct)
        parsD.append({})
        curEl += 1
        parsD[curEl]['main'] = mainStruct
        parsD[curEl]['data'] = []
    
    else:
        dicKeys = ['type','value']
        chk = curL[0:2]
        if chk.isspace():
            subStruct = dict.fromkeys(dicKeys)
            res = curL.strip().split(' ')
            subStruct['type'] = res[0]
            subStruct['value'] = res[1].replace('"','')
            parsD[curEl]['data'].append(subStruct)
#print(parsD)
print(json.dumps(parsD))
with open('out.json','w') as fS:
    fS.write(json.dumps(parsD, indent=4))

fC = open('outCmd.txt','w')
cmdLi = []
for el in parsD:
    curM = el['main']
    if curM['dest'] == None:
        cmdS = 'dbus-send --systen --type:{type} {path} {pathMem}'.format(type =curM['type'], pathMem = curM['interface'] + '.' + curM['member'], path = '/' + curM['interface'].replace('.','/'))
    else:
        cmdS = 'dbus-send --systen --type:{type} --dest:{dest} {path} {pathMem}'.format(type =curM['type'], pathMem = curM['interface'] + '.' + curM['member'], path = '/' + curM['interface'].replace('.','/'),dest=curM['dest'])
    for elS in el['data']:
        if elS['type'] == 'string':
            cmdS += ' {type}:"{value}"'.format(type=elS['type'], value=elS['value'])
        else:
            cmdS += ' {type}:{value}'.format(type=elS['type'], value=elS['value'])
    print(cmdS)
    cmdLi.append(cmdS)
for wEl in cmdLi:
    fC.write(wEl + '\n')
fC.close()