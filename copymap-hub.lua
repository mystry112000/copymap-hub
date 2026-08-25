--!native
--!optimize 2
--!divine-intellect
local function string_find(s, pattern, init)
return string.find(s, pattern, init, true)
end
local function arrayToDict(t, mixedMode, valueOverride, typeStrict)
local tmp = {}
if mixedMode then
for any1, any2 in t do
if type(any1) == string.char(110,117,109,98,101,114) then
tmp[any2] = valueOverride or true
elseif type(any2) == string.char(116,97,98,108,101) then
tmp[any1] = arrayToDict(any2, mixedMode) else
tmp[any1] = any2
end
end
else
for _, key in t do
if not typeStrict or typeStrict and type(key) == typeStrict then
tmp[key] = true
end
end
end
return tmp
end
local GLOBAL_ENV = getgenv and getgenv() or _G or shared
local service = setmetatable({}, {
__index = function(self, serviceName)
local o, s = pcall(Instance.new, serviceName)
local Service = o and s
or game:GetService(serviceName)
or settings():GetService(serviceName)
or UserSettings():GetService(serviceName)
if Service then
self[serviceName] = Service
end
return Service
end,
})
local StreamBuffer = {}
do
StreamBuffer.__index = StreamBuffer
local DEFAULT_CAPACITY = 4096
function StreamBuffer.new(initialCapacity)
local cap = initialCapacity or DEFAULT_CAPACITY
return setmetatable({ buf = buffer.create(cap), len = 0, cap = cap }, StreamBuffer)
end
function StreamBuffer:reserve(extra)
local needed = self.len + extra
if needed <= self.cap then return end
local newCap = self.cap
while newCap < needed do newCap *= 2 end
local newBuf = buffer.create(newCap)
buffer.copy(newBuf, 0, self.buf, 0, self.len)
self.buf = newBuf
self.cap = newCap
end
function StreamBuffer:allocRegion(size)
self:reserve(size)
local base = self.len
self.len += size
return base
end
function StreamBuffer:writeu8(v)
self:reserve(1)
buffer.writeu8(self.buf, self.len, v)
self.len += 1
end
function StreamBuffer:writeu16(v)
self:reserve(2)
buffer.writeu16(self.buf, self.len, v)
self.len += 2
end
function StreamBuffer:writei16(v)
self:reserve(2)
buffer.writei16(self.buf, self.len, v)
self.len += 2
end
function StreamBuffer:writeu32(v)
self:reserve(4)
buffer.writeu32(self.buf, self.len, v)
self.len += 4
end
function StreamBuffer:writei32(v)
self:reserve(4)
buffer.writei32(self.buf, self.len, v)
self.len += 4
end
function StreamBuffer:writef32(v)
self:reserve(4)
buffer.writef32(self.buf, self.len, v)
self.len += 4
end
function StreamBuffer:writef64(v)
self:reserve(8)
buffer.writef64(self.buf, self.len, v)
self.len += 8
end
function StreamBuffer:writestring(s)
local n = #s
self:reserve(n)
buffer.writestring(self.buf, self.len, s)
self.len += n
end
function StreamBuffer:writeLenString(s)
self:writeu32(#s)
self:writestring(s)
end
function StreamBuffer:fill(value, count)
self:reserve(count)
buffer.fill(self.buf, self.len, value, count)
self.len += count
end
function StreamBuffer:pokeu8(offset, v)
buffer.writeu8(self.buf, offset, v)
end
function StreamBuffer:tostring()
return buffer.readstring(self.buf, 0, self.len)
end
end
local global_container
do
local globalenv = getgenv and getgenv() or _G or shared
global_container = globalenv.globalcontainer
if not global_container then
global_container = {}
globalenv.globalcontainer = global_container
end
local genvs = {}
if getgenv then table.insert(genvs, getgenv()) end
table.insert(genvs, shared)
table.insert(genvs, _G)
local calllimit = 0
do
local function determineCalllimit()
calllimit = calllimit + 1
determineCalllimit()
end
pcall(determineCalllimit)
end
local function isEmpty(dict)
for _ in next, dict do return end
return true
end
local depth, printresults, hardlimit, query, antioverflow, matchedall
local function recurseEnv(env, envname)
if global_container == env then return end
if antioverflow[env] then return end
antioverflow[env] = true
depth = depth + 1
for name, val in next, env do
if matchedall then break end
local Type = type(val)
if Type == string.char(116,97,98,108,101) then
if depth < hardlimit then recurseEnv(val, name) end
elseif Type == string.char(102,117,110,99,116,105,111,110) then
name = string.lower(tostring(name))
local matched
for methodname, pattern in next, query do
if pattern(name, envname) then
global_container[methodname] = val
if not matched then matched = {} end
table.insert(matched, methodname)
if printresults then print(methodname, name) end
end
end
if matched then
for _, methodname in next, matched do query[methodname] = nil end
matchedall = isEmpty(query)
if matchedall then break end
end
end
end
depth = depth - 1
end
local function finder(Query, ForceSearch, CustomCallLimit, PrintResults)
antioverflow = {}
query = {}
do
local function Find(String, Pattern)
return string.find(String, Pattern, nil, true)
end
for methodname, pattern in next, Query do
if not global_container[methodname] or ForceSearch then
if not Find(pattern, string.char(114,101,116,117,114,110)) then pattern = string.char(114,101,116,117,114,110,32) .. pattern end
query[methodname] = loadstring(pattern)
end
end
end
depth = 0
printresults = PrintResults
hardlimit = CustomCallLimit or calllimit
recurseEnv(genvs)
do
local env = getfenv()
for methodname in next, Query do
if not global_container[methodname] then global_container[methodname] = env[methodname] end
end
end
hardlimit = nil
depth = nil
printresults = nil
antioverflow = nil
query = nil
end
finder({
base64encode = table.concat({string.char(108,111,99,97,108,32,97,61,123,46,46,46,125,108,111,99,97,108,32,98,61,97,91,49,93,108,111,99,97,108,32,102,117,110,99,116,105,111,110,32,99,40,97,44,98,41,114,101,116,117,114,110,32,115,116,114,105,110,103,46,102,105,110,100,40,97,44,98,44,110,105,108,44,116,114,117,101,41,101,110),string.char(100,59,114,101,116,117,114,110,32,99,40,98,44,34,101,110,99,111,100,101,34,41,97,110,100,40,99,40,98,44,34,98,97,115,101,54,52,34,41,111,114,32,99,40,115,116,114,105,110,103,46,108,111,119,101,114,40,116,111,115,116,114,105,110,103,40,97,91,50,93,41,41,44,34,98,97,115,101,54,52),string.char(34,41,41)}),
base64decode = table.concat({string.char(108,111,99,97,108,32,97,61,123,46,46,46,125,108,111,99,97,108,32,98,61,97,91,49,93,108,111,99,97,108,32,102,117,110,99,116,105,111,110,32,99,40,97,44,98,41,114,101,116,117,114,110,32,115,116,114,105,110,103,46,102,105,110,100,40,97,44,98,44,110,105,108,44,116,114,117,101,41,101,110),string.char(100,59,114,101,116,117,114,110,32,99,40,98,44,34,100,101,99,111,100,101,34,41,97,110,100,40,99,40,98,44,34,98,97,115,101,54,52,34,41,111,114,32,99,40,115,116,114,105,110,103,46,108,111,119,101,114,40,116,111,115,116,114,105,110,103,40,97,91,50,93,41,41,44,34,98,97,115,101,54,52),string.char(34,41,41)}),
gethiddenproperty = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,103,101,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,104,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110),string.char(100,40,46,46,46,44,34,112,114,111,112,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,115,117,98,40,46,46,46,44,35,46,46,46,41,32,126,61,32,34,115,34)}),
gethui = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,103,101,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,104,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110),string.char(100,40,46,46,46,44,34,117,105,34,44,110,105,108,44,116,114,117,101,41)}),
getnilinstances = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,110,105,108,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,103,101,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,115),string.char(117,98,40,46,46,46,44,35,46,46,46,41,32,61,61,32,34,115,34)}), getscriptbytecode = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,103,101,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,115,99,114,105,112,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110),string.char(103,46,102,105,110,100,40,46,46,46,44,34,98,121,116,101,99,111,100,101,34,44,110,105,108,44,116,114,117,101,41)}), protectgui = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,112,114,111,116,101,99,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,117,105,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,110,111,116,32,115),string.char(116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,117,110,34,44,110,105,108,44,116,114,117,101,41)}),
setrbxclipboard = table.concat({string.char(115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,115,101,116,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102,105,110,100,40,46,46,46,44,34,114,98,120,34,44,110,105,108,44,116,114,117,101,41,32,97,110,100,32,115,116,114,105,110,103,46,102),string.char(105,110,100,40,46,46,46,44,34,99,108,105,112,98,111,97,114,100,34,44,110,105,108,44,116,114,117,101,41)}),
}, true, 10)
end
local identify_executor = identifyexecutor or getexecutorname or whatexecutor
local EXECUTOR_NAME = identify_executor and identify_executor() or ""
local setrbxclipboard = global_container.setrbxclipboard
local gethiddenproperty = global_container.gethiddenproperty
local gethiddenproperty_fallback
local lz4compress = lz4compress
local zstdcompress = zstdcompress
local appendfile = appendfile
local isfile = isfile
local readfile = readfile
local writefile = writefile
local getscriptbytecode = global_container.getscriptbytecode local base64encode = global_container.base64encode
local base64decode = global_container.base64decode
local sharedStringId = 1e15 local sharedStrings = setmetatable({}, {
__index = function(self, str)
local id = base64encode(tostring(sharedStringId)) sharedStringId += 1
self[str] = id return id
end,
})
local inheritedProperties = {}
local defaultInstances = {}
local referents, refSize = setmetatable({}, { __mode = string.char(107,115) }), 0 local function getRef(instance)
local ref = referents[instance]
if not ref then
ref = refSize
referents[instance] = ref
refSize += 1
end
return ref
end
local function index(self, index_name)
return self[index_name]
end
local FULL_VERSION
if not pcall(function()
FULL_VERSION = version()
end) then
if not pcall(function()
FULL_VERSION = settings():GetService(string.char(68,101,98,117,103,83,101,116,116,105,110,103,115)).RobloxVersion
end) then
if not pcall(function()
FULL_VERSION = service.RunService:GetRobloxVersion()
end) then
FULL_VERSION = string.char(85,78,75,78,79,87,78)
end
end
end
local CLIENT_VERSION = tonumber(string.match(FULL_VERSION, string.char(37,100,43,37,46,40,37,100,43,41))) or 9e9
local __BREAK = string.char(95,95,66,82,69,65,75) .. service.HttpService:GenerateGUID(false)
local USSI_FOLDER = string.char(117,115,115,105,95,99,97,99,104,101,47)
pcall(function()
makefolder(USSI_FOLDER)
end)
local Type_Ids = {
[string.char(115,116,114,105,110,103)] = 1,
[string.char(98,111,111,108)] = 2,
[string.char(105,110,116)] = 3,
[string.char(102,108,111,97,116)] = 4,
[string.char(100,111,117,98,108,101)] = 5,
[string.char(85,68,105,109)] = 6,
[string.char(85,68,105,109,50)] = 7,
[string.char(82,97,121)] = 8,
[string.char(70,97,99,101,115)] = 9,
[string.char(65,120,101,115)] = 10,
[string.char(66,114,105,99,107,67,111,108,111,114)] = 11,
[string.char(67,111,108,111,114,51)] = 12,
[string.char(86,101,99,116,111,114,50)] = 13,
[string.char(86,101,99,116,111,114,51)] = 14,
[string.char(86,101,99,116,111,114,50,105,110,116,49,54)] = 15,
[string.char(67,70,114,97,109,101)] = 16,
[string.char(69,110,117,109)] = 18,
[string.char(82,101,102,101,114,101,110,116)] = 19,
[string.char(86,101,99,116,111,114,51,105,110,116,49,54)] = 20,
[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101)] = 21,
[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101)] = 22,
[string.char(78,117,109,98,101,114,82,97,110,103,101)] = 23,
[string.char(82,101,99,116)] = 24,
[string.char(80,104,121,115,105,99,97,108,80,114,111,112,101,114,116,105,101,115)] = 25,
[string.char(67,111,108,111,114,51,117,105,110,116,56)] = 26,
[string.char(105,110,116,54,52)] = 27,
[string.char(83,104,97,114,101,100,83,116,114,105,110,103)] = 28,
[string.char(79,112,116,105,111,110,97,108,67,111,111,114,100,105,110,97,116,101,70,114,97,109,101)] = 30,
[string.char(85,110,105,113,117,101,73,100)] = 31,
[string.char(70,111,110,116)] = 32,
[string.char(83,101,99,117,114,105,116,121,67,97,112,97,98,105,108,105,116,105,101,115)] = 33,
[string.char(67,111,110,116,101,110,116)] = 34,
}
local Attribute_Type_Ids =
{ [string.char(110,105,108)] = 0x01,
string = 0x02,
boolean = 0x03,
int32 = 0x04,
number = 0x06, ValueArray = 0x07,
ValueTable = 0x08, UDim = 0x09,
UDim2 = 0x0A,
Ray = 0x0B,
Faces = 0x0C,
Axes = 0x0D,
BrickColor = 0x0E,
Color3 = 0x0F,
Vector2 = 0x10,
Vector3 = 0x11,
Vector2int16 = 0x12,
Vector3int16 = 0x13,
CFrame = 0x14,
EnumItem = 0x15,
NumberSequence = 0x17,
NumberSequenceKeypoint = 0x18,
ColorSequence = 0x19,
ColorSequenceKeypoint = 0x1A,
NumberRange = 0x1B,
Rect = 0x1C,
PhysicalProperties = 0x1D,
Color3uint8 = 0x1E,
Region3 = 0x1F,
Region3int16 = 0x20,
Font = 0x21,
SecurityCapabilities = 0x22,
Path2DControlPoint = 0x23,
TweenInfo = 0x24,
}
local CFrame_Rotation_Ids = {
[table.concat({string.char(92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54),string.char(51)})] = 0x02,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48),string.char(92,48)})] = 0x03,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92),string.char(49,57,49)})] = 0x05,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48),string.char(92,48,92,48)})] = 0x06,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49),string.char(57,49)})] = 0x07,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92),string.char(48)})] = 0x09,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50),string.char(56,92,54,51)})] = 0x0a,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92),string.char(48,92,48)})] = 0x0c,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92),string.char(48)})] = 0x0d,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48),string.char(92,48)})] = 0x0e,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92),string.char(48,92,48)})] = 0x10,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48),string.char(92,49,50,56)})] = 0x11,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92),string.char(49,57,49)})] = 0x14,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48),string.char(92,49,50,56)})] = 0x15,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56),string.char(92,54,51)})] = 0x17,
[table.concat({string.char(92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48),string.char(92,48,92,48,92,49,50,56)})] = 0x18,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50),string.char(56,92,54,51)})] = 0x19,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92),string.char(48,92,48)})] = 0x1b,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48),string.char(92,49,50,56,92,49,57,49)})] = 0x1c,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92),string.char(48,92,48)})] = 0x1e,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92),string.char(48,92,48)})] = 0x1f,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48),string.char(92,48,92,48)})] = 0x20,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,54,51,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92),string.char(48,92,48)})] = 0x22,
[table.concat({string.char(92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,49,50,56,92,48,92,48,92,49,50,56,92,49,57,49,92,48,92,48,92,48,92,48,92,48),string.char(92,48,92,48,92,49,50,56)})] = 0x23,
}
local rotationBuffer = buffer.create(36)
local function rawBasisString(r00, r01, r02, r10, r11, r12, r20, r21, r22)
buffer.writef32(rotationBuffer, 0, r00)
buffer.writef32(rotationBuffer, 4, r01)
buffer.writef32(rotationBuffer, 8, r02)
buffer.writef32(rotationBuffer, 12, r10)
buffer.writef32(rotationBuffer, 16, r11)
buffer.writef32(rotationBuffer, 20, r12)
buffer.writef32(rotationBuffer, 24, r20)
buffer.writef32(rotationBuffer, 28, r21)
buffer.writef32(rotationBuffer, 32, r22)
return buffer.tostring(rotationBuffer)
end
local EMPTY_BUFFER = buffer.create(0)
local BASE_CAPABILITIES
pcall(function()
BASE_CAPABILITIES = SecurityCapabilities.new()
end)
local CAPABILITY_BITS = {
Plugin = 0,
LocalUser = 1,
WritePlayer = 2,
RobloxScript = 3,
RobloxEngine = 4,
NotAccessible = 5,
RunClientScript = 8,
RunServerScript = 9,
AccessOutsideWrite = 11,
Unassigned = 15,
LoadUnownedAsset = 16,
LoadString = 17,
ScriptGlobals = 18,
CreateInstances = 19,
Basic = 20,
Audio = 21,
DataStore = 22,
Network = 23,
Physics = 24,
UI = 25,
CSG = 26,
Chat = 27,
Animation = 28,
AvatarAppearance = 29,
Input = 30,
Environment = 31,
RemoteEvent = 32,
LegacySound = 33,
Players = 34,
CapabilityControl = 35,
AssetRead = 36,
AssetManagement = 37,
DynamicGeneration = 38,
PlatformAvatarEditing = 39,
AssetCreateUpdate = 40,
Capture = 41,
SensitiveInput = 42,
Monetization = 43,
LoadOwnedAsset = 44,
Social = 45,
ServerCommunication = 46,
Logging = 47,
PromptExternalPurchase = 48,
Groups = 49,
Teleport = 50,
Consequences = 51,
Material = 52,
AvatarBehavior = 53,
RemoteCommand = 59,
InternalTest = 60,
PluginOrOpenCloud = 61,
Assistant = 62,
Restricted = 63,
}
local function capabilityHalves(raw)
local lo, hi = 0, 0
for _, flag in string.split(tostring(raw), string.char(32,124,32)) do
local b = CAPABILITY_BITS[flag]
if b then
if b < 32 then
lo = bit32.bor(lo, bit32.lshift(1, b))
else
hi = bit32.bor(hi, bit32.lshift(1, b - 32))
end
end
end
return lo, hi
end
local function capabilityNumber(raw)
local lo, hi = capabilityHalves(raw)
return hi * 0x100000000 + lo
end
local function countBits(...)
local Value = 0
for i, bit in { ... } do
if bit then
Value += 2 ^ (i - 1)
end
end
return Value
end
local function cframeToQuaternion(cframe)
local _, _, _, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cframe:GetComponents()
local trace = R00 + R11 + R22
local S, qW, qX, qY, qZ
if trace > 0 then
S = math.sqrt(1 + trace) * 2
qW = 0.25 * S
qX = (R21 - R12) / S
qY = (R02 - R20) / S
qZ = (R10 - R01) / S
elseif (R00 > R11) and (R00 > R22) then
S = math.sqrt(1 + R00 - R11 - R22) * 2
qW = (R21 - R12) / S
qX = 0.25 * S
qY = (R01 + R10) / S
qZ = (R02 + R20) / S
elseif R11 > R22 then
S = math.sqrt(1 + R11 - R00 - R22) * 2
qW = (R02 - R20) / S
qX = (R01 + R10) / S
qY = 0.25 * S
qZ = (R12 + R21) / S
else
S = math.sqrt(1 + R22 - R00 - R11) * 2
qW = (R10 - R01) / S
qX = (R02 + R20) / S
qY = (R12 + R21) / S
qZ = 0.25 * S
end
if qW < 0 then
qW, qX, qY, qZ = -qW, -qX, -qY, -qZ
end
return qX, qY, qZ, qW
end
local function classifyTable(t)
local len = #t
if len == 0 then
len = nil
end
if next(t, len) == nil then
return string.char(86,97,108,117,101,65,114,114,97,121)
else
return string.char(86,97,108,117,101,84,97,98,108,101)
end
end
local function resolveTypeName(value)
local t = typeof(value)
if t == string.char(116,97,98,108,101) then
return classifyTable(value)
end
return t
end
local scratch = buffer.create(8)
local function rotf(v)
buffer.writef32(scratch, 0, v)
return bit32.lrotate(buffer.readu32(scratch, 0), 1)
end
local function zigzag32(v)
return (v < 0) and (2 * -v - 1) or (2 * v)
end
local function splitU64(v)
local hi = math.floor(v / 4294967296)
return hi, v - hi * 4294967296
end
local function zigzag64(v)
local neg = v < 0
local hi, lo = splitU64(neg and -v or v)
local carry = bit32.extract(lo, 31)
lo = bit32.lshift(lo, 1)
hi = bit32.bor(bit32.lshift(hi, 1), carry)
if neg then if lo == 0 then
lo, hi = 0xFFFFFFFF, hi - 1
else
lo -= 1
end
end
return hi, lo
end
local function zigzagHalves(hi, lo)
local sign = bit32.extract(hi, 31)
local shi = bit32.bor(bit32.lshift(hi, 1), bit32.extract(lo, 31))
local slo = bit32.lshift(lo, 1)
if sign == 1 then
shi, slo = bit32.bnot(shi), bit32.bnot(slo)
end
return shi, slo
end
local function u32FromHex(hex, at)
return tonumber(string.sub(hex, at, at + 7), 16)
end
local function pokeU32Planes(sbuf, o, n, v)
sbuf:pokeu8(o, bit32.rshift(v, 24))
sbuf:pokeu8(o + n, bit32.band(bit32.rshift(v, 16), 0xFF))
sbuf:pokeu8(o + 2 * n, bit32.band(bit32.rshift(v, 8), 0xFF))
sbuf:pokeu8(o + 3 * n, bit32.band(v, 0xFF))
end
local function pokeU64Planes(sbuf, o, n, hi, lo)
pokeU32Planes(sbuf, o, n, hi)
pokeU32Planes(sbuf, o + 4 * n, n, lo)
end
local function interleavedU32Plane(sbuf, n, base, getU32ForIndex)
for i = 1, n do
pokeU32Planes(sbuf, base + (i - 1), n, getU32ForIndex(i))
end
end
local function writeRefPlane(sbuf, n, base, getRef)
local lastRef = nil
interleavedU32Plane(sbuf, n, base, function(i)
local ref = getRef(i)
local acc = lastRef and (ref - lastRef) or ref
lastRef = ref
return zigzag32(acc)
end)
end
local function planeEncoder(...)
local getters = { ... }
local k = #getters
return function(sbuf, vals, n)
local base = sbuf:allocRegion(4 * k * n)
local stride = 4 * n
for i = 1, n do
local v = vals[i]
for p = 1, k do
pokeU32Planes(sbuf, base + (p - 1) * stride + (i - 1), n, getters[p](v))
end
end
end
end
local function f32Encoder(...)
local paths = { ... }
return function(sbuf, vals, n)
for i = 1, n do
local v = vals[i]
for _, p in paths do
sbuf:writef32(p(v))
end
end
end
end
local function i16Encoder(...)
local comps = { ... }
return function(sbuf, vals, n)
for i = 1, n do
local v = vals[i]
for _, c in comps do
sbuf:writei16(v[c])
end
end
end
end
local function sequenceEncoder(writeKeypoint)
return function(sbuf, vals, n)
for i = 1, n do
local keypoints = vals[i].Keypoints
sbuf:writeu32(#keypoints)
for _, kp in keypoints do
writeKeypoint(sbuf, kp)
end
end
end
end
local function flagEncoder(bits)
return function(sbuf, vals, n)
for i = 1, n do
local v = vals[i]
local packed = 0
for name, b in bits do
if v[name] then
packed += b
end
end
sbuf:writeu8(packed)
end
end
end
local function writeCFrameBody(sbuf, vals, n, existsOut)
local coordsX, coordsY, coordsZ = table.create(n), table.create(n), table.create(n)
for i = 1, n do
local val = vals[i]
if existsOut then
local has = val ~= nil
existsOut[i] = has
if not has then
val = CFrame.identity
end
end
local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = val:GetComponents()
coordsX[i], coordsY[i], coordsZ[i] = x, y, z
local rotStr = rawBasisString(r00, r01, r02, r10, r11, r12, r20, r21, r22)
local id = CFrame_Rotation_Ids[rotStr]
if id then
sbuf:writeu8(id)
else
sbuf:writeu8(0)
sbuf:writestring(rotStr)
end
end
local posBase = sbuf:allocRegion(12 * n)
local planes = { coordsX, coordsY, coordsZ }
for p = 1, 3 do
local coords = planes[p]
interleavedU32Plane(sbuf, n, posBase + (p - 1) * 4 * n, function(i)
return rotf(coords[i])
end)
end
end
local Attribute_Encoders
Attribute_Encoders = {
_packMultiple = function(encoder, value1, value2, value3)
local buf1, size1 = encoder(value1)
local buf2, size2 = encoder(value2)
local len = size1 + size2
local buf3, size3
if value3 ~= nil then
buf3, size3 = encoder(value3)
len += size3
end
local b = buffer.create(len)
buffer.copy(b, 0, buf1)
buffer.copy(b, size1, buf2)
if value3 ~= nil then
buffer.copy(b, size1 + size2, buf3)
end
return b, len
end,
_makeSequence = function(keypoint_handler, keypointSize)
return function(raw)
local keypoints = raw.Keypoints
local n = #keypoints
local len = 4 + keypointSize * n
local b = buffer.create(len)
buffer.writeu32(b, 0, n)
local offset = 4
for _, keypoint in keypoints do
keypoint_handler(keypoint, b, offset)
offset += keypointSize
end
return b, len
end
end,
_writeI64LE = function(b, offset, raw)
local low = bit32.band(raw, 0xFFFFFFFF)
local high = (raw - low) / 0x100000000
buffer.writei32(b, offset, low)
buffer.writei32(b, offset + 4, high)
end,
_packF32 = nil,
_packI16 = nil,
_makeVectorPacker = function(writeFunc, elementSize)
return function(X, Y, Z)
local len = Z and (elementSize * 3) or (elementSize * 2)
local b = buffer.create(len)
writeFunc(b, 0, X)
writeFunc(b, elementSize, Y)
if Z then
writeFunc(b, elementSize * 2, Z)
end
return b, len
end
end,
[string.char(110,105,108)] = function(raw)
return EMPTY_BUFFER, 0
end,
[string.char(115,116,114,105,110,103)] = function(raw)
local raw_len = #raw
local len = 4 + raw_len
local b = buffer.create(len)
buffer.writeu32(b, 0, raw_len)
buffer.writestring(b, 4, raw)
return b, len
end,
[string.char(98,111,111,108,101,97,110)] = function(raw)
local b = buffer.create(1)
buffer.writeu8(b, 0, raw and 1 or 0)
return b, 1
end,
[string.char(110,117,109,98,101,114)] = function(raw) local b = buffer.create(8)
buffer.writef64(b, 0, raw)
return b, 8
end,
[string.char(86,97,108,117,101,65,114,114,97,121)] = function(raw)
local n = 0
for k in raw do
if type(k) == string.char(110,117,109,98,101,114) and k > n and k == math.floor(k) and k >= 1 then
n = k
end
end
local bufs = table.create(n)
local len = 4
local count = 0
for i = 1, n do
local value = raw[i]
local b, size
if value == nil then
b = buffer.create(1)
buffer.writeu8(b, 0, 0x01)
size = 1
else
local valueTypeName = resolveTypeName(value)
local typeId = Attribute_Type_Ids[valueTypeName]
local descriptor = Attribute_Encoders[valueTypeName]
if not descriptor then
continue
end
local dataBuf, dataSize = descriptor(value)
b = buffer.create(1 + dataSize)
buffer.writeu8(b, 0, typeId)
buffer.copy(b, 1, dataBuf)
size = 1 + dataSize
end
count += 1
bufs[count] = b
len += size
end
local b = buffer.create(len)
buffer.writeu32(b, 0, count)
local offset = 4
for i = 1, count do
local bb = bufs[i]
buffer.copy(b, offset, bb)
offset += buffer.len(bb)
end
return b, len
end,
[string.char(86,97,108,117,101,84,97,98,108,101)] = function(raw)
local keys = {}
local keyMap = {}
local n = 0
for k in raw do
n += 1
local keyStr = tostring(k)
keys[n] = keyStr
keyMap[keyStr] = k
end
table.sort(keys)
local bufs = table.create(n)
local len = 4
local count = 0
for i = 1, n do
local keyStr = keys[i]
local value = raw[keyMap[keyStr]]
local valueTypeName = resolveTypeName(value)
local typeId = Attribute_Type_Ids[valueTypeName]
local descriptor = Attribute_Encoders[valueTypeName]
if not descriptor then
continue
end
local dataBuf, dataSize = descriptor(value)
local keyLen = #keyStr
local size = 4 + keyLen + 1 + dataSize
local b = buffer.create(size)
buffer.writeu32(b, 0, keyLen)
buffer.writestring(b, 4, keyStr)
buffer.writeu8(b, 4 + keyLen, typeId)
buffer.copy(b, 4 + keyLen + 1, dataBuf)
count += 1
bufs[count] = b
len += size
end
local b = buffer.create(len)
buffer.writeu32(b, 0, count)
local offset = 4
for i = 1, count do
local bb = bufs[i]
buffer.copy(b, offset, bb)
offset += buffer.len(bb)
end
return b, len
end,
[string.char(85,68,105,109)] = function(raw)
local b = buffer.create(8)
buffer.writef32(b, 0, raw.Scale)
buffer.writei32(b, 4, raw.Offset)
return b, 8
end,
[string.char(85,68,105,109,50)] = function(raw)
return Attribute_Encoders._packMultiple(Attribute_Encoders[string.char(85,68,105,109)], raw.X, raw.Y)
end,
[string.char(82,97,121)] = function(raw)
return Attribute_Encoders._packMultiple(Attribute_Encoders[string.char(86,101,99,116,111,114,51)], raw.Origin, raw.Direction)
end,
[string.char(70,97,99,101,115)] = function(raw)
local b = buffer.create(4)
buffer.writeu32(b, 0, countBits(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front))
return b, 4
end,
[string.char(65,120,101,115)] = function(raw)
local b = buffer.create(4)
buffer.writeu32(b, 0, countBits(raw.X, raw.Y, raw.Z))
return b, 4
end,
[string.char(66,114,105,99,107,67,111,108,111,114)] = function(raw)
local b = buffer.create(4)
buffer.writeu32(b, 0, raw.Number)
return b, 4
end,
[string.char(67,111,108,111,114,51)] = function(raw)
return Attribute_Encoders._packF32(raw.R, raw.G, raw.B)
end,
[string.char(86,101,99,116,111,114,50)] = function(raw)
return Attribute_Encoders._packF32(raw.X, raw.Y)
end,
[string.char(86,101,99,116,111,114,51)] = function(raw)
return Attribute_Encoders._packF32(raw.X, raw.Y, raw.Z)
end,
[string.char(86,101,99,116,111,114,50,105,110,116,49,54)] = function(raw)
return Attribute_Encoders._packI16(raw.X, raw.Y)
end,
[string.char(86,101,99,116,111,114,51,105,110,116,49,54)] = function(raw)
return Attribute_Encoders._packI16(raw.X, raw.Y, raw.Z)
end,
[string.char(67,70,114,97,109,101)] = function(raw)
local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
local rotation_ID = CFrame_Rotation_Ids[rawBasisString(R00, R01, R02, R10, R11, R12, R20, R21, R22)]
local len = rotation_ID and 13 or 49
local b = buffer.create(len)
local _packF32 = Attribute_Encoders._packF32
local position = _packF32(X, Y, Z)
buffer.copy(b, 0, position)
if rotation_ID then
buffer.writeu8(b, 12, rotation_ID)
else
buffer.writeu8(b, 12, 0x0)
local xBasis = _packF32(R00, R01, R02)
buffer.copy(b, 13, xBasis)
local yBasis = _packF32(R10, R11, R12)
buffer.copy(b, 13 + 12, yBasis)
local zBasis = _packF32(R20, R21, R22)
buffer.copy(b, 13 + 24, zBasis)
end
return b, len
end,
[string.char(69,110,117,109,73,116,101,109)] = function(raw)
local nameBuf, nameSize = Attribute_Encoders[string.char(115,116,114,105,110,103)](tostring(raw.EnumType))
local len = nameSize + 4
local b = buffer.create(len)
buffer.copy(b, 0, nameBuf)
buffer.writeu32(b, nameSize, raw.Value)
return b, len
end,
[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101)] = nil,
[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101,75,101,121,112,111,105,110,116)] = function(keypoint, b, offset)
if not b then
return Attribute_Encoders._packF32(keypoint.Envelope, keypoint.Time, keypoint.Value)
end
buffer.writef32(b, offset, keypoint.Envelope)
offset += 4
buffer.writef32(b, offset, keypoint.Time)
offset += 4
buffer.writef32(b, offset, keypoint.Value)
end,
[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101)] = nil,
[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101,75,101,121,112,111,105,110,116)] = function(keypoint, b, offset)
local value = Attribute_Encoders[string.char(67,111,108,111,114,51)](keypoint.Value)
if not b then
b = buffer.create(20)
offset = 0
end
buffer.writef32(b, offset, 0)
offset += 4
buffer.writef32(b, offset, keypoint.Time)
offset += 4
buffer.copy(b, offset, value)
return b, 20
end,
[string.char(78,117,109,98,101,114,82,97,110,103,101)] = function(raw)
return Attribute_Encoders._packF32(raw.Min, raw.Max)
end,
[string.char(82,101,99,116)] = function(raw)
return Attribute_Encoders._packMultiple(Attribute_Encoders[string.char(86,101,99,116,111,114,50)], raw.Min, raw.Max)
end,
[string.char(80,104,121,115,105,99,97,108,80,114,111,112,101,114,116,105,101,115)] = function(raw)
local b = buffer.create(25)
buffer.writeu8(b, 0, 1)
buffer.writef32(b, 1, raw.Density)
buffer.writef32(b, 5, raw.Friction)
buffer.writef32(b, 9, raw.Elasticity)
buffer.writef32(b, 13, raw.FrictionWeight)
buffer.writef32(b, 17, raw.ElasticityWeight)
buffer.writef32(b, 21, raw.AcousticAbsorption)
return b, 25
end,
[string.char(67,111,108,111,114,51,117,105,110,116,56)] = function(raw)
local b = buffer.create(3)
buffer.writeu8(b, 0, math.floor(raw.R * 255))
buffer.writeu8(b, 1, math.floor(raw.G * 255))
buffer.writeu8(b, 2, math.floor(raw.B * 255))
return b, 3
end,
[string.char(82,101,103,105,111,110,51)] = function(raw)
local Translation = raw.CFrame.Position
local HalfSize = raw.Size * 0.5
return Attribute_Encoders._packMultiple(
Attribute_Encoders[string.char(86,101,99,116,111,114,51)],
Translation - HalfSize,
Translation + HalfSize
)
end,
[string.char(82,101,103,105,111,110,51,105,110,116,49,54)] = function(raw)
return Attribute_Encoders._packMultiple(Attribute_Encoders[string.char(86,101,99,116,111,114,51,105,110,116,49,54)], raw.Min, raw.Max)
end,
[string.char(70,111,110,116)] = function(raw)
local encoder = Attribute_Encoders[string.char(115,116,114,105,110,103)]
local familyBuf, familySize = encoder(raw.Family)
local faceIdBuf, faceIdSize = encoder("")
local len = 3 + familySize + faceIdSize
local b = buffer.create(len)
local hasWeight, weight = pcall(index, raw, string.char(87,101,105,103,104,116))
local hasStyle, style = pcall(index, raw, string.char(83,116,121,108,101))
buffer.writeu16(b, 0, hasWeight and weight.Value or 0)
buffer.writeu8(b, 2, hasStyle and style.Value or 0)
buffer.copy(b, 3, familyBuf)
buffer.copy(b, 3 + familySize, faceIdBuf)
return b, len
end,
[string.char(83,101,99,117,114,105,116,121,67,97,112,97,98,105,108,105,116,105,101,115)] = function(raw)
local b = buffer.create(8)
if raw == BASE_CAPABILITIES then
return b, 8
end
Attribute_Encoders._writeI64LE(b, 0, capabilityNumber(raw))
return b, 8
end,
[string.char(80,97,116,104,50,68,67,111,110,116,114,111,108,80,111,105,110,116)] = function(raw)
return Attribute_Encoders._packMultiple(
Attribute_Encoders[string.char(85,68,105,109,50)],
raw.Position,
raw.LeftTangent,
raw.RightTangent
)
end,
[string.char(84,119,101,101,110,73,110,102,111)] = function(raw)
local b = buffer.create(21)
buffer.writef32(b, 0, raw.Time)
buffer.writef32(b, 4, raw.DelayTime)
buffer.writei32(b, 8, raw.RepeatCount)
buffer.writeu32(b, 12, raw.EasingStyle.Value)
buffer.writeu32(b, 16, raw.EasingDirection.Value)
buffer.writeu8(b, 20, raw.Reverses and 1 or 0)
return b, 21
end,
}
do Attribute_Encoders[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101)] =
Attribute_Encoders._makeSequence(Attribute_Encoders[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101,75,101,121,112,111,105,110,116)], 12)
Attribute_Encoders[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101)] =
Attribute_Encoders._makeSequence(Attribute_Encoders[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101,75,101,121,112,111,105,110,116)], 20)
end
do Attribute_Encoders._packF32 = Attribute_Encoders._makeVectorPacker(buffer.writef32, 4)
Attribute_Encoders._packI16 = Attribute_Encoders._makeVectorPacker(buffer.writei16, 2)
end
local Binary_Encoders = {
[string.char(115,116,114,105,110,103)] = function(sbuf, vals, n)
for i = 1, n do
sbuf:writeLenString(vals[i])
end
end,
[string.char(98,111,111,108)] = function(sbuf, vals, n)
local base = sbuf:allocRegion(n)
for i = 1, n do
sbuf:pokeu8(base + (i - 1), vals[i] and 1 or 0)
end
end,
[string.char(105,110,116)] = planeEncoder(zigzag32),
[string.char(102,108,111,97,116)] = planeEncoder(rotf),
[string.char(100,111,117,98,108,101)] = function(sbuf, vals, n)
for i = 1, n do
sbuf:writef64(vals[i])
end
end,
[string.char(85,68,105,109)] = planeEncoder(function(v)
return rotf(v.Scale)
end, function(v)
return zigzag32(v.Offset)
end),
[string.char(85,68,105,109,50)] = planeEncoder(function(v)
return rotf(v.X.Scale)
end, function(v)
return rotf(v.Y.Scale)
end, function(v)
return zigzag32(v.X.Offset)
end, function(v)
return zigzag32(v.Y.Offset)
end),
[string.char(82,97,121)] = f32Encoder(function(v)
return v.Origin.X
end, function(v)
return v.Origin.Y
end, function(v)
return v.Origin.Z
end, function(v)
return v.Direction.X
end, function(v)
return v.Direction.Y
end, function(v)
return v.Direction.Z
end),
[string.char(70,97,99,101,115)] = flagEncoder({ Right = 1, Top = 2, Back = 4, Left = 8, Bottom = 16, Front = 32 }),
[string.char(65,120,101,115)] = flagEncoder({ X = 1, Y = 2, Z = 4 }),
[string.char(66,114,105,99,107,67,111,108,111,114)] = planeEncoder(function(v)
return v.Number
end),
[string.char(67,111,108,111,114,51)] = planeEncoder(function(v)
return rotf(v.R)
end, function(v)
return rotf(v.G)
end, function(v)
return rotf(v.B)
end),
[string.char(86,101,99,116,111,114,50)] = planeEncoder(function(v)
return rotf(v.X)
end, function(v)
return rotf(v.Y)
end),
[string.char(86,101,99,116,111,114,51)] = planeEncoder(function(v)
return rotf(v.X)
end, function(v)
return rotf(v.Y)
end, function(v)
return rotf(v.Z)
end),
[string.char(86,101,99,116,111,114,50,105,110,116,49,54)] = i16Encoder(string.char(88), string.char(89)),
[string.char(67,70,114,97,109,101)] = function(sbuf, vals, n)
writeCFrameBody(sbuf, vals, n, nil)
end,
[string.char(69,110,117,109)] = planeEncoder(function(v)
return v.Value
end),
[string.char(82,101,102,101,114,101,110,116)] = function(sbuf, vals, n, refs)
writeRefPlane(sbuf, n, sbuf:allocRegion(4 * n), function(i)
local val = vals[i]
return (val and refs[val]) or -1
end)
end,
[string.char(86,101,99,116,111,114,51,105,110,116,49,54)] = i16Encoder(string.char(88), string.char(89), string.char(90)),
[string.char(78,117,109,98,101,114,83,101,113,117,101,110,99,101)] = sequenceEncoder(function(sbuf, kp)
sbuf:writef32(kp.Time)
sbuf:writef32(kp.Value)
sbuf:writef32(kp.Envelope)
end),
[string.char(67,111,108,111,114,83,101,113,117,101,110,99,101)] = sequenceEncoder(function(sbuf, kp)
local c = kp.Value
sbuf:writef32(kp.Time)
sbuf:writef32(c.R)
sbuf:writef32(c.G)
sbuf:writef32(c.B)
sbuf:writef32(0) end),
[string.char(78,117,109,98,101,114,82,97,110,103,101)] = f32Encoder(function(v)
return v.Min
end, function(v)
return v.Max
end),
[string.char(82,101,99,116)] = planeEncoder(function(v)
return rotf(v.Min.X)
end, function(v)
return rotf(v.Min.Y)
end, function(v)
return rotf(v.Max.X)
end, function(v)
return rotf(v.Max.Y)
end),
[string.char(80,104,121,115,105,99,97,108,80,114,111,112,101,114,116,105,101,115)] = function(sbuf, vals, n)
for i = 1, n do
local val = vals[i]
if val then
sbuf:writeu8(3)
sbuf:writef32(val.Density)
sbuf:writef32(val.Friction)
sbuf:writef32(val.Elasticity)
sbuf:writef32(val.FrictionWeight)
sbuf:writef32(val.ElasticityWeight)
sbuf:writef32(val.AcousticAbsorption)
else
sbuf:writeu8(0)
end
end
end,
[string.char(67,111,108,111,114,51,117,105,110,116,56)] = function(sbuf, vals, n)
local base = sbuf:allocRegion(3 * n)
for i = 1, n do
local val = vals[i]
sbuf:pokeu8(base + (i - 1), math.floor(val.R * 255 + 0.5))
sbuf:pokeu8(base + n + (i - 1), math.floor(val.G * 255 + 0.5))
sbuf:pokeu8(base + 2 * n + (i - 1), math.floor(val.B * 255 + 0.5))
end
end,
[string.char(105,110,116,54,52)] = function(sbuf, vals, n)
local base = sbuf:allocRegion(8 * n)
for i = 1, n do
pokeU64Planes(sbuf, base + (i - 1), n, zigzag64(vals[i]))
end
end,
[string.char(83,104,97,114,101,100,83,116,114,105,110,103)] = function(sbuf, vals, n, sstr)
local base = sbuf:allocRegion(4 * n)
interleavedU32Plane(sbuf, n, base, function(i)
local content = vals[i]
local index = sstr.hashes[content]
if not index then
index = sstr.count
sstr.hashes[content] = index
sstr.count += 1
sstr.order[index + 1] = content
end
return index
end)
end,
[string.char(79,112,116,105,111,110,97,108,67,111,111,114,100,105,110,97,116,101,70,114,97,109,101)] = function(sbuf, vals, n)
local exists = table.create(n)
sbuf:writeu8(0x10) writeCFrameBody(sbuf, vals, n, exists)
sbuf:writeu8(0x02) local boolBase = sbuf:allocRegion(n)
for i = 1, n do
sbuf:pokeu8(boolBase + (i - 1), exists[i] and 1 or 0)
end
end,
[string.char(85,110,105,113,117,101,73,100)] = function(sbuf, vals, n)
local base = sbuf:allocRegion(16 * n)
for i = 1, n do
local val = vals[i]
local o = base + (i - 1)
local hex = string.gsub(val, string.char(37,45), "")
local randHi, randLo = zigzagHalves(u32FromHex(hex, 1), u32FromHex(hex, 9))
pokeU32Planes(sbuf, o, n, u32FromHex(hex, 25))
pokeU32Planes(sbuf, o + 4 * n, n, u32FromHex(hex, 17))
pokeU32Planes(sbuf, o + 8 * n, n, randHi)
pokeU32Planes(sbuf, o + 12 * n, n, randLo)
end
end,
[string.char(70,111,110,116)] = function(sbuf, vals, n)
for i = 1, n do
local val = vals[i]
local hasWeight, weight = pcall(index, val, string.char(87,101,105,103,104,116))
local hasStyle, style = pcall(index, val, string.char(83,116,121,108,101))
sbuf:writeLenString(val.Family)
sbuf:writeu16(hasWeight and weight.Value or 0)
sbuf:writeu8(hasStyle and style.Value or 0)
sbuf:writeu32(0) end
end,
[string.char(83,101,99,117,114,105,116,121,67,97,112,97,98,105,108,105,116,105,101,115)] = function(sbuf, vals, n)
local base = sbuf:allocRegion(8 * n)
for i = 1, n do
local lo, hi = capabilityHalves(vals[i])
pokeU64Planes(sbuf, base + (i - 1), n, zigzagHalves(hi, lo))
end
end,
[string.char(67,111,110,116,101,110,116)] = function(sbuf, vals, n, refs)
local uris, objectRefs = {}, {}
local base = sbuf:allocRegion(4 * n)
interleavedU32Plane(sbuf, n, base, function(i)
local v = vals[i]
if v == nil then
return 0
end
local st = v.SourceType
if st == Enum.ContentSourceType.Uri then
table.insert(uris, v.Uri or "")
return zigzag32(1)
elseif st == Enum.ContentSourceType.Object then
table.insert(objectRefs, v.Object)
return zigzag32(2)
end
return 0
end)
sbuf:writeu32(#uris)
for _, uri in uris do
sbuf:writeLenString(uri)
end
local m = #objectRefs
sbuf:writeu32(m)
if m > 0 then
writeRefPlane(sbuf, m, sbuf:allocRegion(4 * m), function(i)
return (refs and refs[objectRefs[i]]) or -1
end)
end
sbuf:writeu32(0) end,
}
for datatype, sameAs in
{
[string.char(78,101,116,65,115,115,101,116,82,101,102)] = string.char(83,104,97,114,101,100,83,116,114,105,110,103),
[string.char(67,111,110,116,101,110,116,73,100)] = string.char(115,116,114,105,110,103),
[string.char(66,105,110,97,114,121,83,116,114,105,110,103)] = string.char(115,116,114,105,110,103),
[string.char(80,114,111,116,101,99,116,101,100,83,116,114,105,110,103)] = string.char(115,116,114,105,110,103),
}
do
Type_Ids[datatype] = Type_Ids[sameAs]
Binary_Encoders[datatype] = Binary_Encoders[sameAs]
end
local ESCAPES_PATTERN = string.char(91,38,60,62,92,34,39,92,48,92,49,45,92,57,92,49,49,45,92,49,50,92,49,52,45,92,51,49,92,49,50,55,45,92,50,53,53,93) local ESCAPES = {
[string.char(38)] = string.char(38,97,109,112,59), [string.char(60)] = string.char(38,108,116,59), [string.char(62)] = string.char(38,103,116,59), [string.char(34)] = string.char(38,35,51,52,59), [string.char(39)] = string.char(38,35,51,57,59), [string.char(92,48)] = "",
}
for rangeStart, rangeEnd in string.gmatch(ESCAPES_PATTERN, string.char(40,46,41,37,45,40,46,41)) do
for charCode = string.byte(rangeStart), string.byte(rangeEnd) do
ESCAPES[string.char(charCode)] = string.char(38,35) .. charCode .. string.char(59)
end
end
local XML_Encoders
XML_Encoders = {
_cdata = function(raw) return string.char(60,33,91,67,68,65,84,65,91) .. raw .. string.char(93,93,62)
end,
_normalizeNumber = function(raw)
if raw ~= raw then
return string.char(78,65,78)
elseif raw == math.huge then
return string.char(73,78,70)
elseif raw == -math.huge then
return string.char(45,73,78,70)
end
return raw
end,
_normalizeRange = function(raw)
return raw ~= raw and string.char(48) or raw end,
_minMax = function(min, max, encoder)
return string.char(60,109,105,110,62) .. encoder(min) .. string.char(60,47,109,105,110,62,60,109,97,120,62) .. encoder(max) .. string.char(60,47,109,97,120,62)
end,
_makeSequence = function(keypoint_handler)
return function(raw)
local sequence = ""
for _, keypoint in raw.Keypoints do
sequence ..= keypoint_handler(keypoint)
end
return sequence
end
end,
_vector = function(X, Y, Z)
local Value = string.char(60,88,62) .. X .. string.char(60,47,88,62,60,89,62) .. Y .. string.char(60,47,89,62)
if Z then
Value ..= string.char(60,90,62) .. Z .. string.char(60,47,90,62)
end
return Value
end,
Axes = function(raw)
return string.char(60,97,120,101,115,62) .. countBits(raw.X, raw.Y, raw.Z) .. string.char(60,47,97,120,101,115,62)
end,
BinaryString = function(raw) return raw == "" and "" or base64encode(raw)
end,
BrickColor = function(raw)
return raw.Number end,
CFrame = function(raw)
local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = raw:GetComponents()
return XML_Encoders._vector(X, Y, Z)
.. string.char(60,82,48,48,62)
.. R00
.. string.char(60,47,82,48,48,62,60,82,48,49,62)
.. R01
.. string.char(60,47,82,48,49,62,60,82,48,50,62)
.. R02
.. string.char(60,47,82,48,50,62,60,82,49,48,62)
.. R10
.. string.char(60,47,82,49,48,62,60,82,49,49,62)
.. R11
.. string.char(60,47,82,49,49,62,60,82,49,50,62)
.. R12
.. string.char(60,47,82,49,50,62,60,82,50,48,62)
.. R20
.. string.char(60,47,82,50,48,62,60,82,50,49,62)
.. R21
.. string.char(60,47,82,50,49,62,60,82,50,50,62)
.. R22
.. string.char(60,47,82,50,50,62),
string.char(67,111,111,114,100,105,110,97,116,101,70,114,97,109,101)
end,
Color3 = function(raw)
return string.char(60,82,62) .. raw.R .. string.char(60,47,82,62,60,71,62) .. raw.G .. string.char(60,47,71,62,60,66,62) .. raw.B .. string.char(60,47,66,62)
end,
Color3uint8 = function(raw)
return 0xFF000000
+ (math.floor(raw.R * 255) * 0x10000)
+ (math.floor(raw.G * 255) * 0x100)
+ math.floor(raw.B * 255)
end,
ColorSequence = nil,
ColorSequenceKeypoint = function(keypoint)
local _normalizeRange = XML_Encoders._normalizeRange
local color3 = keypoint.Value
return _normalizeRange(keypoint.Time)
.. string.char(32)
.. _normalizeRange(color3.R)
.. string.char(32)
.. _normalizeRange(color3.G)
.. string.char(32)
.. _normalizeRange(color3.B)
.. string.char(32,48,32)
end,
Content = function(raw) local SourceType = raw.SourceType
return SourceType == Enum.ContentSourceType.None and string.char(60,110,117,108,108,62,60,47,110,117,108,108,62)
or SourceType == Enum.ContentSourceType.Uri and string.char(60,117,114,105,62) .. XML_Encoders.string(raw.Uri) .. string.char(60,47,117,114,105,62)
or SourceType == Enum.ContentSourceType.Object and string.char(60,82,101,102,62) .. getRef(raw.Object) .. string.char(60,47,82,101,102,62)
end,
ContentId = function(raw) return raw == "" and string.char(60,110,117,108,108,62,60,47,110,117,108,108,62) or string.char(60,117,114,108,62) .. XML_Encoders.string(raw) .. string.char(60,47,117,114,108,62), string.char(67,111,110,116,101,110,116)
end,
CoordinateFrame = function(raw)
return string.char(60,67,70,114,97,109,101,62) .. XML_Encoders.CFrame(raw) .. string.char(60,47,67,70,114,97,109,101,62)
end,
EnumItem = function(raw)
return raw.Value, string.char(116,111,107,101,110)
end,
Faces = function(raw)
return string.char(60,102,97,99,101,115,62) .. countBits(raw.Right, raw.Top, raw.Back, raw.Left, raw.Bottom, raw.Front) .. string.char(60,47,102,97,99,101,115,62)
end,
Font = function(raw)
local hasWeight, weight = pcall(index, raw, string.char(87,101,105,103,104,116))
local hasStyle, style = pcall(index, raw, string.char(83,116,121,108,101))
return string.char(60,70,97,109,105,108,121,62)
.. XML_Encoders.ContentId(raw.Family)
.. string.char(60,47,70,97,109,105,108,121,62,60,87,101,105,103,104,116,62)
.. (hasWeight and XML_Encoders.EnumItem(weight) or "")
.. string.char(60,47,87,101,105,103,104,116,62,60,83,116,121,108,101,62)
.. (hasStyle and style.Name or "") .. string.char(60,47,83,116,121,108,101,62)
end,
NetAssetRef = nil,
NumberRange = function(raw) local _normalizeRange = XML_Encoders._normalizeRange
return _normalizeRange(raw.Min) .. string.char(32) .. _normalizeRange(raw.Max) end,
NumberSequence = nil,
NumberSequenceKeypoint = function(keypoint)
local _normalizeRange = XML_Encoders._normalizeRange
return _normalizeRange(keypoint.Time)
.. string.char(32)
.. _normalizeRange(keypoint.Value)
.. string.char(32)
.. _normalizeRange(keypoint.Envelope)
.. string.char(32)
end,
PhysicalProperties = function(raw)
local CustomPhysics = string.char(60,67,117,115,116,111,109,80,104,121,115,105,99,115,62) .. XML_Encoders.bool(raw and true or false) .. string.char(60,47,67,117,115,116,111,109,80,104,121,115,105,99,115,62)
return raw
and CustomPhysics .. string.char(60,68,101,110,115,105,116,121,62) .. raw.Density .. string.char(60,47,68,101,110,115,105,116,121,62,60,70,114,105,99,116,105,111,110,62) .. raw.Friction .. string.char(60,47,70,114,105,99,116,105,111,110,62,60,69,108,97,115,116,105,99,105,116,121,62) .. raw.Elasticity .. string.char(60,47,69,108,97,115,116,105,99,105,116,121,62,60,70,114,105,99,116,105,111,110,87,101,105,103,104,116,62) .. raw.FrictionWeight .. string.char(60,47,70,114,105,99,116,105,111,110,87,101,105,103,104,116,62,60,69,108,97,115,116,105,99,105,116,121,87,101,105,103,104,116,62) .. raw.ElasticityWeight .. string.char(60,47,69,108,97,115,116,105,99,105,116,121,87,101,105,103,104,116,62,60,65,99,111,117,115,116,105,99,65,98,115,111,114,112,116,105,111,110,62) .. raw.AcousticAbsorption .. string.char(60,47,65,99,111,117,115,116,105,99,65,98,115,111,114,112,116,105,111,110,62)
or CustomPhysics
end,
ProtectedString = function(raw)
return string_find(raw, string.char(93,93,62)) and string.gsub(raw, ESCAPES_PATTERN, ESCAPES) or XML_Encoders._cdata(raw)
end,
Ray = function(raw)
local vector3 = XML_Encoders.Vector3
return string.char(60,111,114,105,103,105,110,62) .. vector3(raw.Origin) .. string.char(60,47,111,114,105,103,105,110,62,60,100,105,114,101,99,116,105,111,110,62) .. vector3(raw.Direction) .. string.char(60,47,100,105,114,101,99,116,105,111,110,62)
end,
Rect = function(raw)
return XML_Encoders._minMax(raw.Min, raw.Max, XML_Encoders.Vector2), string.char(82,101,99,116,50,68)
end,
Region3 = function(raw) local Translation = raw.CFrame.Position
local HalfSize = raw.Size * 0.5
return XML_Encoders._minMax(Translation - HalfSize, Translation + HalfSize, XML_Encoders.Vector3)
end,
Region3int16 = function(raw)
return XML_Encoders._minMax(raw.Min, raw.Max, XML_Encoders.Vector3int16)
end,
SharedString = function(raw)
return sharedStrings[XML_Encoders.BinaryString(raw)]
end,
SecurityCapabilities = function(raw)
if raw == BASE_CAPABILITIES then
return 0
end
return capabilityNumber(raw)
end,
TweenInfo = function(raw)
local _normalizeNumber = XML_Encoders._normalizeNumber
return string.char(84,105,109,101,58)
.. _normalizeNumber(raw.Time)
.. string.char(32,68,101,108,97,121,84,105,109,101,58)
.. _normalizeNumber(raw.DelayTime)
.. string.char(32,82,101,112,101,97,116,67,111,117,110,116,58)
.. _normalizeNumber(raw.RepeatCount)
.. string.char(32,82,101,118,101,114,115,101,115,58)
.. (raw.Reverses and string.char(84,114,117,101) or string.char(70,97,108,115,101))
.. string.char(32,69,97,115,105,110,103,68,105,114,101,99,116,105,111,110,58)
.. raw.EasingDirection.Name
.. string.char(32,69,97,115,105,110,103,83,116,121,108,101,58)
.. raw.EasingStyle.Name
end,
UDim = function(raw)
return string.char(60,83,62) .. raw.Scale .. string.char(60,47,83,62,60,79,62) .. raw.Offset .. string.char(60,47,79,62)
end,
UDim2 = function(raw)
local X, Y = raw.X, raw.Y
return string.char(60,88,83,62)
.. X.Scale
.. string.char(60,47,88,83,62,60,88,79,62)
.. X.Offset
.. string.char(60,47,88,79,62,60,89,83,62)
.. Y.Scale
.. string.char(60,47,89,83,62,60,89,79,62)
.. Y.Offset
.. string.char(60,47,89,79,62)
end,
UniqueId = function(raw) return string.gsub(raw, string.char(45), "") end,
Vector2 = function(raw)
return XML_Encoders._vector(raw.X, raw.Y)
end,
Vector2int16 = nil,
Vector3 = function(raw)
return XML_Encoders._vector(raw.X, raw.Y, raw.Z)
end,
Vector3int16 = nil,
bool = function(raw)
return raw and string.char(116,114,117,101) or string.char(102,97,108,115,101)
end,
double = nil, float = nil, int = nil, int64 = nil, string = function(raw)
return (raw == nil or raw == "") and ""
or string_find(raw, string.char(93,93,62)) and string.gsub(raw, ESCAPES_PATTERN, ESCAPES)
or XML_Encoders._cdata(string.gsub(raw, string.char(92,48), ""))
end,
}
do XML_Encoders.NumberSequence = XML_Encoders._makeSequence(XML_Encoders.NumberSequenceKeypoint)
XML_Encoders.ColorSequence = XML_Encoders._makeSequence(XML_Encoders.ColorSequenceKeypoint)
end
for encoderName, redirectName in
{
NetAssetRef = string.char(83,104,97,114,101,100,83,116,114,105,110,103),
Vector2int16 = string.char(86,101,99,116,111,114,50),
Vector3int16 = string.char(86,101,99,116,111,114,51),
double = string.char(95,110,111,114,109,97,108,105,122,101,78,117,109,98,101,114),
float = string.char(95,110,111,114,109,97,108,105,122,101,78,117,109,98,101,114),
int = string.char(95,110,111,114,109,97,108,105,122,101,78,117,109,98,101,114),
int64 = string.char(95,110,111,114,109,97,108,105,122,101,78,117,109,98,101,114),
}
do
XML_Encoders[encoderName] = XML_Encoders[redirectName]
end
local ClassList, FetchAPI
local RiskyServicesDisabled = { UGC = false, Encoding = false, Reflection = false }
do
local ClassPropertyExceptions = arrayToDict({
Whitelist = {
MeshPart = { string.char(67,111,108,108,105,115,105,111,110,70,105,100,101,108,105,116,121) },
PartOperation = { string.char(67,111,108,108,105,115,105,111,110,70,105,100,101,108,105,116,121) },
TriangleMeshPart = { string.char(67,111,108,108,105,115,105,111,110,70,105,100,101,108,105,116,121) },
},
Blacklist = {
LuaSourceContainer = { string.char(83,99,114,105,112,116,71,117,105,100) },
Instance = { string.char(85,110,105,113,117,101,73,100), string.char(72,105,115,116,111,114,121,73,100) },
},
}, true)
local function AttributesSerialize(attrs, header_bytes)
local count = 0
local buffer_size = 4
local sorted = {}
local formatted = table.clone(attrs)
if header_bytes then
buffer_size += #header_bytes
end
for attr, val in attrs do
local t = resolveTypeName(val)
local encoder = Attribute_Encoders[t]
if not encoder then
continue
end
count += 1
sorted[count] = attr
local attr_size
formatted[attr], attr_size = encoder(val)
buffer_size += 5 + #attr + attr_size
end
table.sort(sorted)
local b = buffer.create(buffer_size)
local offset = 0
if header_bytes then
for _, header_byte in header_bytes do
buffer.writeu8(b, offset, header_byte)
offset += 1
end
end
buffer.writeu32(b, offset, count)
offset += 4
local stringEncoder = Attribute_Encoders[string.char(115,116,114,105,110,103)]
for _, attr in sorted do
local nameBuf, nameSize = stringEncoder(attr)
buffer.copy(b, offset, nameBuf)
offset += nameSize
buffer.writeu8(b, offset, Attribute_Type_Ids[resolveTypeName(attrs[attr])])
offset += 1
local bb = formatted[attr]
buffer.copy(b, offset, bb)
offset += buffer.len(bb)
end
return buffer.tostring(b)
end
local function AttenuationSerialize(attenuations)
if not next(attenuations) then
return string.char(92,48) end
local count = 0
local sorted = {}
for key in attenuations do
count += 1
sorted[count] = key
end
table.sort(sorted)
local b = buffer.create(1 + count * 8)
local offset = 1
for _, key in sorted do
buffer.writef32(b, offset, key)
offset += 4
buffer.writef32(b, offset, attenuations[key])
offset += 4
end
return buffer.tostring(b)
end
local function TransformsSerialize(transforms)
local n = #transforms
if n == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local b = buffer.create(8 + n * 48)
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, n)
local _packF32 = Attribute_Encoders._packF32
local offset = 8
for _, transform in transforms do
local X, Y, Z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = transform:GetComponents()
local xBasis = _packF32(R00, R01, R02)
buffer.copy(b, offset, xBasis)
offset += 12
local yBasis = _packF32(R10, R11, R12)
buffer.copy(b, offset, yBasis)
offset += 12
local zBasis = _packF32(R20, R21, R22)
buffer.copy(b, offset, zBasis)
offset += 12
local position = _packF32(X, Y, Z)
buffer.copy(b, offset, position)
offset += 12
end
return buffer.tostring(b)
end
local function ServiceVisibilitySerialize(wantVisible)
local ExplorerServiceVisibilityService = game:GetService(string.char(69,120,112,108,111,114,101,114,83,101,114,118,105,99,101,86,105,115,105,98,105,108,105,116,121,83,101,114,118,105,99,101))
local stringEncoder = Attribute_Encoders[string.char(115,116,114,105,110,103)]
local typeId = Attribute_Type_Ids[string.char(115,116,114,105,110,103)]
local count = 0
local buffer_size = 4
local names = {}
local formatted = {}
for _, service in game:GetChildren() do
if ExplorerServiceVisibilityService:GetServiceVisibility(service) == wantVisible then
local name = service.ClassName
local buf, size = stringEncoder(name)
count += 1
names[count] = name
formatted[name] = buf
buffer_size += 1 + size
end
end
if count == 0 then
return string.char(92,48,92,48,92,48,92,48)
end
table.sort(names)
local b = buffer.create(buffer_size)
buffer.writeu32(b, 0, count)
local offset = 4
for _, name in names do
buffer.writeu8(b, offset, typeId)
offset += 1
local bb = formatted[name]
buffer.copy(b, offset, bb)
offset += buffer.len(bb)
end
return buffer.tostring(b)
end
local function encodeTimeTicks(time)
local scaled = time * 2400
if not (scaled >= -2147483648 and scaled < 2147483648) then
return -2147483648
end
return math.round(scaled)
end
local function writeTimesSection(b, offset, keys)
buffer.writeu32(b, offset, 1)
offset += 4
buffer.writeu32(b, offset, #keys)
offset += 4
for _, key in keys do
buffer.writei32(b, offset, encodeTimeTicks(key.Time))
offset += 4
end
return offset
end
local function deriveTangentValueCurve(keys, i)
local key = keys[i]
local isFirst = (i == 1)
local isLast = (i == #keys)
if isLast then
return 0, 0
end
if key.Interpolation == Enum.KeyInterpolationMode.Constant then
return 0, 0
end
if key.Interpolation == Enum.KeyInterpolationMode.Linear then
local nextKey = keys[i + 1]
local t = 1 / (nextKey.Time - key.Time)
return t, t
end
if isFirst then
return 0, 0
end
local prevKey = keys[i - 1]
local deltaPrev = key.Time - prevKey.Time
if prevKey.Interpolation == Enum.KeyInterpolationMode.Constant then
return 0, 0
elseif prevKey.Interpolation == Enum.KeyInterpolationMode.Linear then
local t = 1 / deltaPrev
return t, t
else
local nextKey = keys[i + 1]
local deltaNext = nextKey.Time - key.Time
local t = (1 / deltaPrev + 1 / deltaNext) / 2
return t, t
end
end
local function deriveTangentFloatCurve(keys, i)
local key = keys[i]
local isFirst = (i == 1)
local isLast = (i == #keys)
if isLast then
return 0, 0
end
if key.Interpolation == Enum.KeyInterpolationMode.Constant then
return 0, 0
end
if key.Interpolation == Enum.KeyInterpolationMode.Linear then
local nextKey = keys[i + 1]
local slope = (nextKey.Value - key.Value) / (nextKey.Time - key.Time)
return slope, slope
end
if isFirst then
return 0, 0
end
local prevKey = keys[i - 1]
if prevKey.Interpolation == Enum.KeyInterpolationMode.Constant then
return 0, 0
elseif prevKey.Interpolation == Enum.KeyInterpolationMode.Linear then
local slope = (key.Value - prevKey.Value) / (key.Time - prevKey.Time)
return slope, slope
else
return 0, 0
end
end
local function encodeGuid(uid)
local cleanGuid = string.gsub(uid, string.char(91,123,125,45,93), "")
local bytes = buffer.create(16)
for i = 0, 15 do
local hexByte = string.sub(cleanGuid, (i * 2) + 1, (i * 2) + 2)
local val = tonumber(hexByte, 16) or 0
buffer.writeu8(bytes, i, val)
end
return buffer.tostring(bytes)
end
local NotScriptableFixes = {
Instance = {
AttributesSerialize = function(instance)
local attrs = instance:GetAttributes()
if not next(attrs) then
return ""
end
return AttributesSerialize(attrs)
end,
DefinesCapabilities = string.char(83,97,110,100,98,111,120,101,100),
Tags = function(instance)
local tags = service.CollectionService:GetTags(instance) if #tags == 0 then
return ""
end
return table.concat(tags, string.char(92,48))
end,
},
Path2D = {
PropertiesSerialize = function(instance)
local control_points = instance:GetControlPoints()
local n = #control_points
if n == 0 then
return string.char(92,48,92,48,92,48,92,48)
end
local b = buffer.create(4 + n * 49)
buffer.writeu32(b, 0, n)
local typeId = Attribute_Type_Ids[string.char(80,97,116,104,50,68,67,111,110,116,114,111,108,80,111,105,110,116)]
local encoder = Attribute_Encoders[string.char(80,97,116,104,50,68,67,111,110,116,114,111,108,80,111,105,110,116)]
local offset = 4
for i, point in control_points do
local buf, bufSize = encoder(point)
buffer.writeu8(b, offset, typeId)
offset += 1
buffer.copy(b, offset, buf)
offset += bufSize
end
return buffer.tostring(b)
end,
},
PlayerEmulatorService = {
SerializedEmulatedPolicyInfo = function(instance)
local EmulatedPolicyInfo = instance:GetEmulatedPolicyInfo()
if not next(EmulatedPolicyInfo) then
return ""
end
return AttributesSerialize(EmulatedPolicyInfo)
end,
},
StyleRule = {
PropertiesSerialize = function(instance)
local props = instance:GetProperties()
if not next(props) then
return string.char(92,48,92,48,92,48,92,48)
end
return AttributesSerialize(props)
end,
PropertyTransitionsSerialize = function(instance)
local transitions = instance:GetPropertyTransitions()
if not next(transitions) then
return string.char(92,50,92,48,92,48,92,48,92,48,92,48)
end
return AttributesSerialize(transitions, { 0x02, 0x00 })
end,
},
StyleQuery = {
ConditionsSerialize = function(instance)
local props = instance:GetConditions()
if not next(props) then
return string.char(92,48,92,48,92,48,92,48)
end
return AttributesSerialize(props)
end,
},
FloatCurve = {
ValuesAndTimes = function(instance)
local keys = instance:GetKeys()
if #keys == 0 then
return string.char(92,50,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local valuesPayloadSize = #keys * 14
local b = buffer.create(8 + valuesPayloadSize + 8 + (#keys * 4))
buffer.writeu32(b, 0, 2)
buffer.writeu32(b, 4, #keys)
local offset = 8
for i, key in keys do
local lt, rt = key.LeftTangent, key.RightTangent
local mode = countBits(lt, rt)
if mode == 0 then
lt, rt = deriveTangentFloatCurve(keys, i)
elseif mode == 1 then
rt = lt
elseif mode == 2 then
lt = rt
end
buffer.writeu8(b, offset, key.Interpolation.Value) offset += 1
buffer.writeu8(b, offset, mode)
offset += 1
buffer.writef32(b, offset, key.Value)
offset += 4
buffer.writef32(b, offset, lt)
offset += 4
buffer.writef32(b, offset, rt)
offset += 4
end
offset = writeTimesSection(b, offset, keys)
return buffer.tostring(b)
end,
},
RotationCurve = {
ValuesAndTimes = function(instance)
local keys = instance:GetKeys()
if #keys == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local perKeySize = 25
local b = buffer.create(8 + (#keys * perKeySize) + 8 + (#keys * 4))
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, #keys)
local offset = 8
for _, key in keys do
local lt = key.LeftTangent or 0
local rt = key.RightTangent or 0
local qx, qy, qz, qw = cframeToQuaternion(key.Value)
buffer.writeu8(b, offset, 12 + key.Interpolation.Value) offset += 1
buffer.writef32(b, offset, qx)
offset += 4
buffer.writef32(b, offset, qy)
offset += 4
buffer.writef32(b, offset, qz)
offset += 4
buffer.writef32(b, offset, qw)
offset += 4
buffer.writef32(b, offset, lt)
offset += 4
buffer.writef32(b, offset, rt)
offset += 4
end
offset = writeTimesSection(b, offset, keys)
return buffer.tostring(b)
end,
},
ValueCurve = {
ValuesAndTimes = function(instance)
local keys = instance:GetKeys()
if #keys == 0 then
return string.char(92,50,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local valueTypeName = instance.ValueType local typeId = Attribute_Type_Ids[valueTypeName]
if not typeId then
valueTypeName = resolveTypeName(keys[1].Value) typeId = Attribute_Type_Ids[valueTypeName]
end
local encoder = Attribute_Encoders[valueTypeName]
if not encoder then
return string.char(92,50,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local n = #keys
local bufs = table.create(n)
local sizes = table.create(n)
local valuesPayloadSize = 0
for i, key in keys do
local dataBuf, dataSize = encoder(key.Value)
bufs[i] = dataBuf
sizes[i] = dataSize
valuesPayloadSize += 15 + dataSize
end
local b = buffer.create(8 + valuesPayloadSize + 8 + 4 * n)
buffer.writeu32(b, 0, 2)
buffer.writeu32(b, 4, n)
local offset = 8
for i, key in keys do
local lt, rt = key.LeftTangent, key.RightTangent
local dataSize = sizes[i]
buffer.writeu8(b, offset, key.Interpolation.Value) offset += 1
buffer.writeu8(b, offset, countBits(lt, rt))
offset += 1
buffer.writeu32(b, offset, dataSize + 1)
offset += 4
buffer.writeu8(b, offset, typeId)
offset += 1
buffer.copy(b, offset, bufs[i])
offset += dataSize
if lt == nil and rt == nil then
lt, rt = deriveTangentValueCurve(keys, i)
elseif lt == nil then
lt = rt
elseif rt == nil then
rt = lt
end
buffer.writef32(b, offset, lt)
offset += 4
buffer.writef32(b, offset, rt)
offset += 4
end
offset = writeTimesSection(b, offset, keys)
return buffer.tostring(b)
end,
},
MarkerCurve = {
ValuesAndTimes = function(instance)
local markers = instance:GetMarkers()
local n = #markers
if n == 0 then
return string.char(92,50,92,48,92,48,92,48,92,48,92,48,92,48,92,48,92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local strings_size = 0
for _, marker in markers do
strings_size += #marker.Value + 1
end
local b = buffer.create(8 + strings_size + 8 + (n * 4))
buffer.writeu32(b, 0, 2) buffer.writeu32(b, 4, n)
local offset = 8
for _, marker in markers do
local value = marker.Value
buffer.writestring(b, offset, value)
offset += #value + 1
end
offset = writeTimesSection(b, offset, markers)
return buffer.tostring(b)
end,
},
AnimationNodeDefinition = {
InputPinData = function(instance)
local input_pins = instance:GetOrderedInputPinNames()
local n = #input_pins
if n == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local buffer_size = 8
for _, pin in input_pins do
buffer_size += 4 + #pin
end
local b = buffer.create(buffer_size)
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, n)
local encoder = Attribute_Encoders[string.char(115,116,114,105,110,103)]
local offset = 8
for _, pin in input_pins do
local pinBuf, pinSize = encoder(pin)
buffer.copy(b, offset, pinBuf)
offset += pinSize
end
return buffer.tostring(b)
end,
},
AnimationClip = {
GuidBinaryString = function(instance) return encodeGuid(instance.Guid)
end,
},
AnimationRigData = {
label = function(instance)
local labels = instance:GetLabels() local n = #labels
if n == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local b = buffer.create(8 + n * 4)
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, n)
local offset = 8
for _, label in labels do
buffer.writeu32(b, offset, label)
offset += 4
end
return buffer.tostring(b)
end,
name = function(instance)
local names = instance:GetNames() local n = #names
if n == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local buffer_size = 8
for _, name in names do
buffer_size += 4 + #name
end
local b = buffer.create(buffer_size)
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, n)
local offset = 8
for _, name in names do
buffer.writeu32(b, offset, #name)
offset += 4
end
for _, name in names do
buffer.writestring(b, offset, name)
offset += #name
end
return buffer.tostring(b)
end,
parent = function(instance)
local parents = instance:GetParents() local n = #parents
if n == 0 then
return string.char(92,49,92,48,92,48,92,48,92,48,92,48,92,48,92,48)
end
local b = buffer.create(8 + #parents * 2)
buffer.writeu32(b, 0, 1) buffer.writeu32(b, 4, n)
local offset = 8
for _, parent in parents do
buffer.writeu16(b, offset, parent)
offset += 2
end
return buffer.tostring(b)
end,
postTransform = function(instance)
return TransformsSerialize(instance:GetPostTransforms()) end,
preTransform = function(instance)
return TransformsSerialize(instance:GetPreTransforms()) end,
transform = function(instance)
return TransformsSerialize(instance:GetTransforms()) end,
},
AudioDeviceInput = {
AccessList = function(instance) local userid_accesslist = instance:GetUserIdAccessList()
local n = #userid_accesslist
if n == 0 then
return ""
end
local b = buffer.create(n * 8)
local _writeI64LE = Attribute_Encoders._writeI64LE
local offset = 0
for _, user_id in userid_accesslist do
_writeI64LE(b, offset, user_id)
offset += 8
end
return buffer.tostring(b)
end,
},
AudioEmitter = {
AngleAttenuation = function(instance)
return AttenuationSerialize(instance:GetAngleAttenuation())
end,
DistanceAttenuation = function(instance)
return AttenuationSerialize(instance:GetDistanceAttenuation())
end,
},
AudioListener = {
AngleAttenuation = function(instance)
return AttenuationSerialize(instance:GetAngleAttenuation())
end,
DistanceAttenuation = function(instance)
return AttenuationSerialize(instance:GetDistanceAttenuation())
end,
},
DebuggerBreakpoint = { line = string.char(76,105,110,101) }, BallSocketConstraint = { MaxFrictionTorqueXml = string.char(77,97,120,70,114,105,99,116,105,111,110,84,111,114,113,117,101) },
BasePart = {
Color3uint8 = string.char(67,111,108,111,114),
MaterialVariantSerialized = string.char(77,97,116,101,114,105,97,108,86,97,114,105,97,110,116),
size = string.char(83,105,122,101),
siz = string.char(83,105,122,101),
},
DoubleConstrainedValue = { value = string.char(86,97,108,117,101) },
IntConstrainedValue = { value = string.char(86,97,108,117,101) },
CustomEvent = {
PersistedCurrentValue = function(instance)
local receiver = instance:GetAttachedReceivers()[1]
if receiver then
return receiver:GetCurrentValue()
end
local tempReceiver = Instance.new(string.char(67,117,115,116,111,109,69,118,101,110,116,82,101,99,101,105,118,101,114))
local clone = Instance.fromExisting(instance)
tempReceiver.Source = clone
local value = tempReceiver:GetCurrentValue()
tempReceiver:Destroy()
clone:Destroy()
return value
end,
},
Terrain = {
AcquisitionMethod = string.char(76,97,115,116,85,115,101,100,77,111,100,105,102,105,99,97,116,105,111,110,77,101,116,104,111,100), MaterialColors = function(instance)
local TERRAIN_MATERIAL_COLORS =
{ Enum.Material.Grass,
Enum.Material.Slate,
Enum.Material.Concrete,
Enum.Material.Brick,
Enum.Material.Sand,
Enum.Material.WoodPlanks,
Enum.Material.Rock,
Enum.Material.Glacier,
Enum.Material.Snow,
Enum.Material.Sandstone,
Enum.Material.Mud,
Enum.Material.Basalt,
Enum.Material.Ground,
Enum.Material.CrackedLava,
Enum.Material.Asphalt,
Enum.Material.Cobblestone,
Enum.Material.Ice,
Enum.Material.LeafyGrass,
Enum.Material.Salt,
Enum.Material.Limestone,
Enum.Material.Pavement,
}
local b = buffer.create(69)
local offset = 6 for _, material in TERRAIN_MATERIAL_COLORS do
local color = instance:GetMaterialColor(material)
buffer.writeu8(b, offset, (color.R * 255))
offset += 1
buffer.writeu8(b, offset, (color.G * 255))
offset += 1
buffer.writeu8(b, offset, (color.B * 255))
offset += 1
end
return buffer.tostring(b)
end,
},
BaseWrap = {
TemporaryCageMeshContent = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(84,101,109,112,111,114,97,114,121,67,97,103,101,77,101,115,104,73,100)))
end,
},
MaterialVariant = {
TexturePackContent = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(84,101,120,116,117,114,101,80,97,99,107)))
end,
},
TerrainDetail = {
TexturePackContent = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(84,101,120,116,117,114,101,80,97,99,107)))
end,
},
WrapLayer = {
TemporaryReferenceMeshContent = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(84,101,109,112,111,114,97,114,121,82,101,102,101,114,101,110,99,101,73,100)))
end,
},
TriangleMeshPart = {
FluidFidelityInternal = string.char(70,108,117,105,100,70,105,100,101,108,105,116,121),
},
MeshPart = {
InitialSize = string.char(77,101,115,104,83,105,122,101),
MeshID = string.char(77,101,115,104,73,100),
VertexCount = function(instance) if RiskyServicesDisabled.UGC then
return __BREAK
end
local meshId = instance.MeshId
if meshId == "" then
return __BREAK
end
return #service.UGCValidationService:GetMeshVerts(meshId)
end,
},
PartOperation = {
Content = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(65,115,115,101,116,73,100)))
end,
InitialSize = string.char(77,101,115,104,83,105,122,101),
},
Part = { shape = string.char(83,104,97,112,101), shap = string.char(83,104,97,112,101) },
TrussPart = { style = string.char(83,116,121,108,101) },
FormFactorPart = {
formFactorRaw = string.char(70,111,114,109,70,97,99,116,111,114),
},
Fire = { heat_xml = string.char(72,101,97,116), size_xml = string.char(83,105,122,101) },
Clothing = {
Outfit1Content = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(79,117,116,102,105,116,49)))
end,
Outfit2Content = function(instance)
return Content.fromUri(gethiddenproperty_fallback(instance, string.char(79,117,116,102,105,116,50)))
end,
},
Humanoid = {
Health_XML = string.char(72,101,97,108,116,104),
InternalBodyScale = function(instance) local a = instance.RootPart
if not a then
return __BREAK
end
return instance:GetAccessoryHandleScale(a, Enum.BodyPartR15.RootPart)
end,
InternalHeadScale = function(instance) local a = instance.Parent and instance.Parent:FindFirstChild(string.char(72,101,97,100))
if not a then
return __BREAK
end
return instance:GetAccessoryHandleScale(a, Enum.BodyPartR15.Head).X end,
NetworkHumanoidState = function(instance) return instance:GetState()
end,
},
HumanoidDescription = {
AccessoryBlob = function(instance)
local blob = {}
for _, acc in instance:GetAccessories(false) do
table.insert(blob, {
AssetId = acc.AssetId,
Order = acc.Order,
AccessoryType = acc.AccessoryType.Name,
Puffiness = acc.Puffiness,
})
end
return service.HttpService:JSONEncode(blob)
end,
EmotesDataInternal = function(instance)
local emotes_data = ""
for name, ids in instance:GetEmotes() do
emotes_data ..= name .. string.char(94) .. table.concat(ids, string.char(94)) .. string.char(94,92,92)
end
return emotes_data
end,
EquippedEmotesDataInternal = function(instance)
local equipped_emotes = instance:GetEquippedEmotes()
if #equipped_emotes == 0 then
return ""
end
local equipped_emotes_data = ""
for _, emote in equipped_emotes do
equipped_emotes_data = equipped_emotes_data .. emote.Slot .. string.char(94) .. emote.Name .. string.char(92,92)
end
return equipped_emotes_data
end,
},
LocalizationTable = {
Contents = function(instance)
return instance:GetContents() end,
},
MaterialService = { Use2022MaterialsXml = string.char(85,115,101,50,48,50,50,77,97,116,101,114,105,97,108,115) }, VideoPlayer = {
PlayingReplicating = string.char(73,115,80,108,97,121,105,110,103), },
Model = {
ModelMeshCFrame = function(instance)
return instance:GetModelCFrame() end,
ModelMeshSize = function(instance)
return instance:GetExtentsSize() end,
Scale = function(instance) return instance:GetScale()
end,
ScaleFactor = function(instance)
return instance:GetScale()
end,
WorldPivotData = string.char(87,111,114,108,100,80,105,118,111,116), },
PackageLink = {
PackageContentSerialize = string.char(80,97,99,107,97,103,101,67,111,110,116,101,110,116),
PackageIdSerialize = string.char(80,97,99,107,97,103,101,73,100),
VersionIdSerialize = string.char(86,101,114,115,105,111,110,78,117,109,98,101,114),
},
Players = { MaxPlayersInternal = string.char(77,97,120,80,108,97,121,101,114,115), PreferredPlayersInternal = string.char(80,114,101,102,101,114,114,101,100,80,108,97,121,101,114,115) }, StarterPlayer = {
AvatarJointUpgrade_SerializedRollout = string.char(65,118,97,116,97,114,74,111,105,110,116,85,112,103,114,97,100,101), },
Smoke = { size_xml = string.char(83,105,122,101), opacity_xml = string.char(79,112,97,99,105,116,121), riseVelocity_xml = string.char(82,105,115,101,86,101,108,111,99,105,116,121) },
Sound = {
xmlRead_MinDistance_3 = string.char(82,111,108,108,79,102,102,77,105,110,68,105,115,116,97,110,99,101), xmlRead_MaxDistance_3 = string.char(82,111,108,108,79,102,102,77,97,120,68,105,115,116,97,110,99,101), },
ViewportFrame = {
CameraCFrame = function(instance)
local CurrentCamera = instance.CurrentCamera
return CurrentCamera and CurrentCamera.CFrame or CFrame.identity
end,
CameraFieldOfView = function(instance)
local CurrentCamera = instance.CurrentCamera
return math.rad(CurrentCamera and CurrentCamera.FieldOfView or 70)
end,
},
WeldConstraint = {
CFrame0 = function(instance)
local Part0, Part1 = instance.Part0, instance.Part1
return Part0 and Part1 and Part0.CFrame:ToObjectSpace(Part1.CFrame) or CFrame.identity
end,
CFrame1 = function(instance)
local Part0, Part1 = instance.Part0, instance.Part1
return Part0 and Part1 and Part1.CFrame:ToObjectSpace(Part0.CFrame) or CFrame.identity
end,
Part0Internal = string.char(80,97,114,116,48),
Part1Internal = string.char(80,97,114,116,49),
State = function(instance)
return countBits(instance.Enabled, instance.Active)
end,
},
Workspace = {
CollisionGroups = function(instance) local collision_groups = game:GetService(string.char(80,104,121,115,105,99,115,83,101,114,118,105,99,101)):GetRegisteredCollisionGroups()
local n = #collision_groups
if n == 0 then
return ""
end
local t = table.create(n)
for i, group in collision_groups do
t[i] = group.name .. string.char(94) .. i - 1 .. string.char(94) .. group.mask
end
return table.concat(t, string.char(92,92))
end,
},
WorldRoot = {
CollisionGroupData = function(instance)
local collision_groups = game:GetService(string.char(80,104,121,115,105,99,115,83,101,114,118,105,99,101)):GetRegisteredCollisionGroups()
local n = #collision_groups
if n == 0 then
return string.char(92,49,92,48)
end
local buffer_size = 2 for _, group in collision_groups do
buffer_size += 7 + #group.name end
local b = buffer.create(buffer_size)
buffer.writeu8(b, 0, 1) buffer.writeu8(b, 1, n)
local typeId_int32 = Attribute_Type_Ids[string.char(105,110,116,51,50)]
local offset = 2
for i, group in collision_groups do
local name, id, mask = group.name, i - 1, group.mask
local name_len = #name
buffer.writeu8(b, offset, id) offset += 1
buffer.writeu8(b, offset, typeId_int32) offset += 1
buffer.writei32(b, offset, mask) offset += 4
buffer.writeu8(b, offset, name_len) offset += 1
buffer.writestring(b, offset, name) offset += name_len
end
return buffer.tostring(b)
end,
},
ServiceVisibilityService = { HiddenServices = function()
return ServiceVisibilitySerialize(false)
end,
VisibleServices = function()
return ServiceVisibilitySerialize(true)
end,
},
}
for _, enum_item in Enum.Material:GetEnumItems() do
NotScriptableFixes.MaterialService[enum_item.Name .. string.char(78,97,109,101)] = function(instance)
return instance:GetBaseMaterialOverride(enum_item)
end
end
FetchAPI = function()
local FILE_NAME = USSI_FOLDER .. string.char(65,80,73,95,68,85,77,80,46,106,115,111,110)
local API_Dump
local Max_SecurityCapabilities = SecurityCapabilities.new(unpack(Enum.SecurityCapability:GetEnumItems()))
local filter = { Security = Max_SecurityCapabilities, ExcludeDisplay = true, ExcludeInherited = true }
local APIDUMP_FETCHERS = {
[1] = function()
local res = readfile(FILE_NAME)
if res and res ~= "" then
return service.HttpService:JSONDecode(res)[FULL_VERSION]
end
end,
[2] = function() local client_version_str = tostring(CLIENT_VERSION)
local dump
local matching_versions, matched, is_matched, exact_match = {}, {}
local function process_line(line, noinsert)
local file_version, patch_commit, version_hash =
string.match(line, string.char(34,37,100,43,37,46,40,37,100,43,41,37,46,40,91,94,34,93,43,41,34,58,32,34,40,118,101,114,115,105,111,110,37,45,91,94,34,93,43,41))
if file_version == client_version_str then
is_matched = true
if version_hash and not matched[version_hash] then matched[version_hash] = true
if not noinsert then table.insert(matching_versions, version_hash) end
if string.sub(FULL_VERSION, -#patch_commit) == patch_commit then
return version_hash end
end
elseif is_matched then
return false end
end
local function isFullDump(classes)
for _, class in classes do
for _, member in class.Members do
if member.MemberType == string.char(80,114,111,112,101,114,116,121) then
return member.Default ~= nil
end
end
end
return false end
local function tryFetchDump(url)
local ok, decoded = pcall(function()
local raw = game:HttpGet(url, true)
return service.HttpService:JSONDecode(raw)
end)
return ok and decoded.Classes or nil
end
local function fetchFullApiDump(hash)
local decoded = tryFetchDump(string.char(104,116,116,112,115,58,47,47,115,101,116,117,112,46,114,98,120,99,100,110,46,99,111,109,47) .. hash .. string.char(45,70,117,108,108,45,65,80,73,45,68,117,109,112,46,106,115,111,110))
if decoded and isFullDump(decoded) then
return decoded
end
decoded = tryFetchDump(
table.concat({string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,115,101,116,117,112,45,114,98,120,99,100,110,47,114,111,98,108,111,120,45,102,117,108,108,45,97,112,105,45,100,117,109,112,115,47,114,101,102,115,47,104,101,97,100,115,47),string.char(109,97,105,110,47,102,117,108,108,45,100,117,109,112,115,47)})
.. hash
.. string.char(45,70,117,108,108,45,65,80,73,45,68,117,109,112,46,106,115,111,110)
)
if decoded and isFullDump(decoded) then return decoded
end
return nil
end
do
local o, r = pcall(
game.HttpGet,
game,
table.concat({string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,115,101,116,117,112,45,114,98,120,99,100,110,47,115,101,116,117,112,45,114,98,120,99,100,110,46,103,105,116,104,117,98,46,105,111,47,114,101,102,115,47,104,101,97,100,115),string.char(47,109,97,105,110,47,118,101,114,115,105,111,110,45,104,105,115,116,111,114,121,47,87,105,110,100,111,119,115,47,83,116,117,100,105,111,54,52,46,106,115,111,110)}),
true
)
if o then
local version_history = string.split(r, string.char(92,110))
version_history[#version_history] = nil for i = #version_history, 2, -1 do local res = process_line(version_history[i])
if res == false then
break
elseif res then
exact_match = res
end
end
end
end
do local function fallback_channel(channel)
local ok, res = pcall(function()
return service.HttpService:JSONDecode(
game:HttpGet(
string.char(104,116,116,112,115,58,47,47,99,108,105,101,110,116,115,101,116,116,105,110,103,115,99,100,110,46,114,111,98,108,111,120,46,99,111,109,47,118,50,47,99,108,105,101,110,116,45,118,101,114,115,105,111,110,47,87,105,110,100,111,119,115,83,116,117,100,105,111,54,52)
.. (channel and string.char(47,99,104,97,110,110,101,108,47) .. channel or ""),
true
)
)
end)
if not ok then
return
end
if res.version and res.clientVersionUpload then local line = string.char(34) .. res.version .. string.char(34,58,32,34) .. res.clientVersionUpload
return process_line(line, true)
end
end
if not exact_match then
exact_match = fallback_channel(string.char(122,98,101,116,97)) or fallback_channel() end
end
if exact_match then
dump = fetchFullApiDump(exact_match)
end
if not dump then
for _, version_hash in matching_versions do dump = fetchFullApiDump(version_hash)
if dump then
break
end
end
end
return dump
end,
[3] = function()
if RiskyServicesDisabled.Reflection then
return nil
end
local classes, classes_size = {}, 1
local renames = {
CoordinateFrame = string.char(67,70,114,97,109,101),
Rect2D = string.char(82,101,99,116),
Vector3Int16 = string.char(86,101,99,116,111,114,51,105,110,116,49,54),
Vector2Int16 = string.char(86,101,99,116,111,114,50,105,110,116,49,54),
Region3Int16 = string.char(82,101,103,105,111,110,51,105,110,116,49,54),
}
for _, api_class in service.ReflectionService:GetClasses(filter) do
local members, members_size = {}, 1
local className = api_class.Name
local class = {
Name = className,
Members = members,
Superclass = api_class.Superclass or string.char(60,60,60,82,79,79,84,62,62,62),
}
local permits = api_class.Permits
local tags = {}
if api_class.Service then
table.insert(tags, string.char(83,101,114,118,105,99,101))
elseif permits and permits[string.char(71,101,116,83,101,114,118,105,99,101)] then
table.insert(tags, string.char(83,101,114,118,105,99,101))
elseif not permits or not permits[string.char(78,101,119)] then table.insert(tags, string.char(78,111,116,67,114,101,97,116,97,98,108,101))
end
if #tags ~= 0 then
class.Tags = tags
end
local o, r = pcall(
service.ReflectionService.GetPropertiesOfClass,
service.ReflectionService,
className,
filter
) if o then
for _, property in r do
local propertyName = property.Name
local valueType = property.Type
local valueType_Name = valueType.EngineType
local category = valueType.Category
local member_tags = {}
if not next(property.Permits) then
table.insert(member_tags, string.char(78,111,116,83,99,114,105,112,116,97,98,108,101))
end
if valueType_Name == string.char(69,110,117,109) then
category, valueType_Name = string.char(69,110,117,109), valueType.EnumType
elseif valueType_Name == string.char(82,101,102,84,121,112,101) then
category, valueType_Name = string.char(67,108,97,115,115), valueType.InstanceType
else
valueType_Name = renames[valueType_Name] or valueType_Name
end
local member = {
Name = propertyName,
MemberType = string.char(80,114,111,112,101,114,116,121),
ValueType = { Name = valueType_Name, Category = category },
Serialization = { CanLoad = property.Serialized, CanSave = property.Serialized },
}
if #member_tags ~= 0 then
member.Tags = member_tags
end
members[members_size] = member
members_size += 1
end
end
classes[classes_size] = class
classes_size += 1
end
return classes
end,
[4] = function()
return service.HttpService:JSONDecode(
game:HttpGet(
table.concat({string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,77,97,120,105,109,117,109,65,68,72,68,47,82,111,98,108,111,120,45,67,108,105,101,110,116,45,84,114,97,99,107,101,114,47,114,111,98,108,111,120,47,77,105,110,105,45),string.char(65,80,73,45,68,117,109,112,46,106,115,111,110)}),
true
)
).Classes
end,
}
for i, fetcher in APIDUMP_FETCHERS do
local o, r = pcall(fetcher)
if o and r then
API_Dump = r
if i == 2 then if writefile then
local ok, err =
pcall(writefile, FILE_NAME, service.HttpService:JSONEncode({ [FULL_VERSION] = API_Dump }))
if not ok then
warn(string.char(91,68,69,66,85,71,93,32,68,85,77,80,32,119,114,105,116,101,102,105,108,101,32,101,114,114,111,114), err)
end
end
end
break
elseif r ~= false and 2 < i then
warn(string.char(91,68,69,66,85,71,93,32,70,97,105,108,101,100,32,116,111,32,103,101,116), FULL_VERSION, string.char(118,101,114,115,105,111,110,32,65,80,73,32,68,117,109,112,44,32,116,114,121,105,110,103,32,102,97,108,108,98,97,99,107,115,46,46))
warn(string.char(91,68,69,66,85,71,93,32,77,101,116,104,111,100,32,110,117,109,98,101,114,58), i, string.char(82,101,97,115,111,110,58), r)
end
end
local classList = {}
local tmp_classDict = {}
local ClassesWhitelist, ClassesBlacklist = ClassPropertyExceptions.Whitelist, ClassPropertyExceptions.Blacklist
local API_Dump_Decoded = API_Dump
for _, API_Class in API_Dump_Decoded do
local ClassName = API_Class.Name
local props = {}
for _, Member in API_Class.Members do
local MemberType = Member.MemberType
if MemberType == string.char(80,114,111,112,101,114,116,121) or MemberType == string.char(70,117,110,99,116,105,111,110) then
props[Member.Name] = {
ValueType = MemberType == string.char(80,114,111,112,101,114,116,121) and Member.ValueType.Name,
MemberType = MemberType,
}
end
end
tmp_classDict[ClassName] = props
end
for _, API_Class in API_Dump_Decoded do
local ClassProperties, ClassProperties_size = {}, 1
local Class = {
Properties = ClassProperties,
Superclass = API_Class.Superclass,
NotCreatable = nil,
}
local ClassName = API_Class.Name
local ClassTags = API_Class.Tags
if ClassTags then
local Tags = arrayToDict(ClassTags, nil, nil, string.char(115,116,114,105,110,103))
Class.NotCreatable = Tags.NotCreatable
Class.Service = Tags.Service
end
local NotScriptableFixClass = NotScriptableFixes[ClassName]
local ClassWhitelist, ClassBlacklist = ClassesWhitelist[ClassName], ClassesBlacklist[ClassName]
local ContentProperties
for _, Member in API_Class.Members do
if Member.MemberType == string.char(80,114,111,112,101,114,116,121) then
local Serialization = Member.Serialization
if Serialization.CanLoad then local PropertyName = Member.Name
local ValueType = Member.ValueType
local ValueType_Name = ValueType.Name
if ValueType_Name == string.char(67,111,110,116,101,110,116) or ValueType_Name == string.char(65,115,115,101,116,67,111,110,116,101,110,116,77,97,112) then if not ContentProperties then
ContentProperties = {}
if not RiskyServicesDisabled.Reflection then
local o, properties = pcall(
service.ReflectionService.GetPropertiesOfClass,
service.ReflectionService,
ClassName,
filter
)
if o then
for _, property in properties do
ContentProperties[property.Name] = property.Serialized
end
end
end
end
if ContentProperties[PropertyName] ~= nil then
Serialization.CanSave = ContentProperties[PropertyName]
end
end
if
(Serialization.CanSave or ClassWhitelist and ClassWhitelist[PropertyName])
and not (ClassBlacklist and ClassBlacklist[PropertyName])
then
local MemberTags = Member.Tags
local Special, PreferredDescriptorName
if MemberTags then
for _, tag in MemberTags do
if type(tag) == string.char(116,97,98,108,101) then
PreferredDescriptorName = tag.PreferredDescriptorName
if PreferredDescriptorName and Special then
break
end
elseif tag == string.char(78,111,116,83,99,114,105,112,116,97,98,108,101) then
Special = true
if PreferredDescriptorName then
break
end
end
end
end
local preferredDescriptorProp
if PreferredDescriptorName then
preferredDescriptorProp = tmp_classDict[ClassName][PreferredDescriptorName]
if preferredDescriptorProp == nil
or (
preferredDescriptorProp.MemberType == string.char(80,114,111,112,101,114,116,121)
and ValueType_Name ~= preferredDescriptorProp.ValueType
)
then PreferredDescriptorName = nil
end
end
local Property = {
Name = PropertyName,
Category = ValueType.Category,
ValueType = ValueType_Name,
Special = Special,
CanRead = nil,
}
if string.sub(ValueType_Name, 1, 8) == string.char(79,112,116,105,111,110,97,108) then
Property.Optional = string.sub(ValueType_Name, 9)
end
local NotScriptableFix = NotScriptableFixClass and NotScriptableFixClass[PropertyName]
local accessFunc = PreferredDescriptorName
and (
preferredDescriptorProp.MemberType == string.char(80,114,111,112,101,114,116,121)
and function(instance)
return instance[PreferredDescriptorName]
end
or function(instance) return instance[PreferredDescriptorName](instance)
end
)
Property.Fallback = NotScriptableFix
and (type(NotScriptableFix) == string.char(102,117,110,99,116,105,111,110) and NotScriptableFix or accessFunc and function(
instance
)
local o, r = pcall(accessFunc, instance)
if o then
return r
end
return instance[NotScriptableFix]
end or function(instance)
return instance[NotScriptableFix]
end)
or accessFunc
ClassProperties[ClassProperties_size] = Property
ClassProperties_size += 1
end
end
end
end
classList[ClassName] = Class
end
return classList
end
end
local function synsaveinstance(CustomOptions, CustomOptions2)
if GLOBAL_ENV.USSI then
return
end
GLOBAL_ENV.USSI = true
local totalsize = 0
local StatusText
local OPTIONS = {
mode = string.char(111,112,116,105,109,105,122,101,100),
Binary = true,
CompressionMode = string.char(122,115,116,100),
CompressionLevel = 9,
Decompile = true,
DecompileTimeout = 30,
DecompileJobless = false,
scriptcache = true,
SaveBytecode = false,
BytecodeTimeout = 3,
__DEBUG_MODE = false,
Callback = false,
CopyToClipboard = false, DecompileIgnore = {
string.char(84,101,120,116,67,104,97,116,83,101,114,118,105,99,101),
ModuleScript = nil,
},
IgnoreDefaultPlayerScripts = true,
IgnoreProperties = {},
IgnoreList = { string.char(67,111,114,101,71,117,105), string.char(67,111,114,101,80,97,99,107,97,103,101,115), Packages = false },
ExtraInstances = {},
NilInstances = false,
NilInstancesFixes = {},
SaveCacheInterval = 0x1600 * 10,
ShowStatus = true,
KillAllScripts = true,
SafeMode = false,
BoostFPS = false,
ShutdownWhenDone = false,
AntiIdle = true,
Anonymous = false,
ReadMe = true,
FilePath = false,
AvoidFileOverwrite = true,
Object = false,
IsModel = false,
IgnoreDefaultProperties = true,
IgnoreNotArchivable = true,
IgnorePropertiesOfNotScriptsOnScriptsMode = false,
IgnoreSpecialProperties = false,
IsolateLocalPlayer = false, IsolateLocalPlayerCharacter = false,
IsolatePlayers = false,
IsolateStarterPlayer = false,
SavePlayerCharacters = false,
SaveNotCreatable = false,
NotCreatableFixes = {
"", string.char(65,100,118,97,110,99,101,100,68,114,97,103,103,101,114),
string.char(65,110,105,109,97,116,105,111,110,84,114,97,99,107),
string.char(68,114,97,103,103,101,114),
string.char(80,108,97,121,101,114),
string.char(80,108,97,121,101,114,71,117,105),
string.char(80,108,97,121,101,114,77,111,117,115,101),
string.char(80,108,97,121,101,114,77,111,117,115,101),
string.char(80,108,97,121,101,114,83,99,114,105,112,116,115),
string.char(83,99,114,101,101,110,115,104,111,116,72,117,100),
string.char(83,116,117,100,105,111,68,97,116,97),
string.char(84,101,120,116,67,104,97,116,77,101,115,115,97,103,101),
string.char(84,101,120,116,83,111,117,114,99,101),
string.char(84,111,117,99,104,84,114,97,110,115,109,105,116,116,101,114),
string.char(84,114,97,110,115,108,97,116,111,114),
CloudLocalizationTable = string.char(76,111,99,97,108,105,122,97,116,105,111,110,84,97,98,108,101),
Platform = string.char(80,97,114,116),
Status = string.char(77,111,100,101,108), },
RiskyServicesDisabled = {
UGC = false,
Encoding = false,
Reflection = false,
},
SharedBinaryStrings = false,
TreatUnionsAsParts = false,
AlternativeWritefile = not arrayToDict({ string.char(87,82,68), string.char(88,101,110,111), string.char(90,111,114,97,114,97) })[EXECUTOR_NAME],
OptionsAliases = { Clipboard = string.char(67,111,112,121,84,111,67,108,105,112,98,111,97,114,100),
DecompileScripts = string.char(68,101,99,111,109,112,105,108,101),
FileName = string.char(70,105,108,101,80,97,116,104),
IgnoreArchivable = string.char(73,103,110,111,114,101,78,111,116,65,114,99,104,105,118,97,98,108,101),
IgnoreDefaultProps = string.char(73,103,110,111,114,101,68,101,102,97,117,108,116,80,114,111,112,101,114,116,105,101,115),
InstancesBlacklist = string.char(73,103,110,111,114,101,76,105,115,116),
IsolatePlayerGui = string.char(73,115,111,108,97,116,101,76,111,99,97,108,80,108,97,121,101,114),
SaveCharacters = string.char(83,97,118,101,80,108,97,121,101,114,67,104,97,114,97,99,116,101,114,115),
SaveLocalPlayer = string.char(73,115,111,108,97,116,101,76,111,99,97,108,80,108,97,121,101,114),
SaveNilInstances = string.char(78,105,108,73,110,115,116,97,110,99,101,115),
SaveNonCreatable = string.char(83,97,118,101,78,111,116,67,114,101,97,116,97,98,108,101),
SavePlayerGui = string.char(73,115,111,108,97,116,101,76,111,99,97,108,80,108,97,121,101,114),
SavePlayers = string.char(73,115,111,108,97,116,101,80,108,97,121,101,114,115),
StatusText = string.char(83,104,111,119,83,116,97,116,117,115),
timeout = string.char(68,101,99,111,109,112,105,108,101,84,105,109,101,111,117,116),
},
OptionsAliasesInverse = {
DisableCompression = string.char(67,111,109,112,114,101,115,115,105,111,110,77,111,100,101),
noscripts = string.char(68,101,99,111,109,112,105,108,101),
RemovePlayerCharacters = string.char(83,97,118,101,80,108,97,121,101,114,67,104,97,114,97,99,116,101,114,115),
RemovePlayers = string.char(73,115,111,108,97,116,101,80,108,97,121,101,114,115),
XML = string.char(66,105,110,97,114,121),
},
}
local OPTIONS_lowercase, OptionsAliasesInverse_lowercase, CustomOptions_valid = {}, {}, {}
do
local function buildMap(dest, source, warnLabel)
for k, v in source do
local key = string.lower(k)
if dest[key] then
warn(string.char(68,85,80,76,73,67,65,84,69,32) .. warnLabel, k)
else
dest[key] = v
end
end
end
for o in OPTIONS do
local option = string.lower(o)
if OPTIONS_lowercase[option] then
warn(string.char(68,85,80,76,73,67,65,84,69,32,79,80,84,73,79,78), o)
else
OPTIONS_lowercase[option] = o
end
end
buildMap(OPTIONS_lowercase, OPTIONS.OptionsAliases, string.char(65,76,73,65,83))
buildMap(OptionsAliasesInverse_lowercase, OPTIONS.OptionsAliasesInverse, string.char(73,78,86,69,82,83,69,32,65,76,73,65,83))
end
do local function makeNilinstanceFix(Name, ClassName, Separate)
return function(instance, instancePropertyOverrides)
local Exists
if not Separate then
Exists = OPTIONS.NilInstancesFixes[Name]
end
local Fix
local DoesntExist = not Exists
if DoesntExist then
Fix = Instance.new(ClassName)
if not Separate then
OPTIONS.NilInstancesFixes[Name] = Fix
end
instancePropertyOverrides[Fix] =
{ __Synthetic = true, __Children = { instance }, Properties = { Name = Name } }
else
Fix = Exists
table.insert(instancePropertyOverrides[Fix].__Children, instance)
end
if DoesntExist then
return Fix
end
end
end
OPTIONS.NilInstancesFixes.Animator =
makeNilinstanceFix(string.char(65,110,105,109,97,116,111,114,32,104,97,115,32,116,111,32,98,101,32,112,108,97,99,101,100,32,117,110,100,101,114,32,72,117,109,97,110,111,105,100,32,111,114,32,65,110,105,109,97,116,105,111,110,67,111,110,116,114,111,108,108,101,114), string.char(65,110,105,109,97,116,105,111,110,67,111,110,116,114,111,108,108,101,114))
OPTIONS.NilInstancesFixes.AdPortal = makeNilinstanceFix(string.char(65,100,80,111,114,116,97,108,32,109,117,115,116,32,98,101,32,112,97,114,101,110,116,101,100,32,116,111,32,97,32,80,97,114,116), string.char(80,97,114,116))
OPTIONS.NilInstancesFixes.Attachment =
makeNilinstanceFix(string.char(65,116,116,97,99,104,109,101,110,116,115,32,109,117,115,116,32,98,101,32,112,97,114,101,110,116,101,100,32,116,111,32,97,32,66,97,115,101,80,97,114,116,32,111,114,32,97,110,111,116,104,101,114,32,65,116,116,97,99,104,109,101,110,116), string.char(80,97,114,116)) OPTIONS.NilInstancesFixes.BaseWrap = makeNilinstanceFix(string.char(66,97,115,101,87,114,97,112,32,109,117,115,116,32,98,101,32,112,97,114,101,110,116,101,100,32,116,111,32,97,32,77,101,115,104,80,97,114,116), string.char(77,101,115,104,80,97,114,116))
OPTIONS.NilInstancesFixes.PackageLink = makeNilinstanceFix(string.char(80,97,99,107,97,103,101,32,97,108,114,101,97,100,121,32,104,97,115,32,97,32,80,97,99,107,97,103,101,76,105,110,107), string.char(70,111,108,100,101,114), true)
if CustomOptions2 and type(CustomOptions2) == string.char(116,97,98,108,101) then
local tmp = CustomOptions
local Type = typeof(tmp)
CustomOptions = CustomOptions2
if Type == string.char(73,110,115,116,97,110,99,101) then
CustomOptions.Object = tmp
elseif Type == string.char(116,97,98,108,101) and typeof(tmp[1]) == string.char(73,110,115,116,97,110,99,101) then
CustomOptions.ExtraInstances = tmp
OPTIONS.IsModel = true
end
end
local Type = typeof(CustomOptions)
if Type == string.char(116,97,98,108,101) then
if typeof(CustomOptions[1]) == string.char(73,110,115,116,97,110,99,101) then
OPTIONS.mode = string.char(105,110,118,97,108,105,100,109,111,100,101)
OPTIONS.ExtraInstances = CustomOptions
OPTIONS.IsModel = true
CustomOptions = {}
else
for key, value in CustomOptions do
local k = string.lower(key)
local option = OPTIONS_lowercase[k]
local invert = false
if not option then
option = OptionsAliasesInverse_lowercase[k]
invert = option ~= nil
end
if option then
local finalValue
if invert then
finalValue = not value
else
finalValue = value
end
OPTIONS[option] = finalValue
CustomOptions_valid[option] = true
end
end
end
elseif Type == string.char(73,110,115,116,97,110,99,101) then
OPTIONS.mode = string.char(105,110,118,97,108,105,100,109,111,100,101)
OPTIONS.Object = CustomOptions
CustomOptions = {}
else
CustomOptions = {}
end
end
if not writefile and not OPTIONS.Callback then
local function coreCall(method, ...)
local StarterGui = service.StarterGui
method = StarterGui[method]
if not method then
return
end
for _ = 1, 10 do local success, result = pcall(method, StarterGui, ...)
if success then
return result
end
task.wait(1)
end
end
local text = table.concat({string.char(70,117,110,99,116,105,111,110,32,34,119,114,105,116,101,102,105,108,101,34,32,105,115,32,78,79,84,32,97,118,97,105,108,97,98,108,101,92,110,85,115,101,32,116,104,101,32,79,112,116,105,111,110,32,34,67,97,108,108,98,97,99,107,34,32,105,110,115,116,101,97,100,32,102,111,114,32,110,111,119),string.char(32,40,99,104,101,99,107,32,100,111,99,115,41)})
coreCall(string.char(83,101,116,67,111,114,101), string.char(83,101,110,100,78,111,116,105,102,105,99,97,116,105,111,110), {
Title = string.char(83,65,86,69,73,78,83,84,65,78,67,69,32,69,82,82,79,82),
Text = text,
Duration = 15,
Icon = string.char(114,98,120,97,115,115,101,116,105,100,58,47,47,57,48,55,50,57,50,48,54,48,57),
})
coreCall(string.char(83,101,116,67,111,114,101), string.char(83,101,110,100,78,111,116,105,102,105,99,97,116,105,111,110), {
Title = string.char(83,65,86,69,73,78,83,84,65,78,67,69,32,69,82,82,79,82),
Text = string.char(80,108,101,97,115,101,32,97,115,107,32,121,111,117,114,32,101,120,101,99,117,116,111,114,39,115,32,100,101,118,101,108,111,112,101,114,115,32,116,111,32,97,100,100,32,119,114,105,116,101,102,105,108,101),
Duration = 15,
Icon = string.char(114,98,120,97,115,115,101,116,105,100,58,47,47,57,48,55,50,57,50,48,54,48,57),
})
warn(text)
GLOBAL_ENV.USSI = nil
return
end
do
local RiskyOption = OPTIONS.RiskyServicesDisabled
if type(RiskyOption) == string.char(116,97,98,108,101) then
RiskyServicesDisabled.UGC = RiskyOption.UGC
RiskyServicesDisabled.Encoding = RiskyOption.Encoding
RiskyServicesDisabled.Reflection = RiskyOption.Reflection
end
end
local InstancesOverrides = {}
local DecompileIgnore, IgnoreList, IgnoreProperties, NotCreatableFixes =
arrayToDict(OPTIONS.DecompileIgnore, true),
arrayToDict(OPTIONS.IgnoreList, true),
arrayToDict(OPTIONS.IgnoreProperties),
arrayToDict(OPTIONS.NotCreatableFixes, true, string.char(70,111,108,100,101,114))
local CopyToClipboard = OPTIONS.CopyToClipboard
local Callback = OPTIONS.Callback
local CompressionLevel = OPTIONS.CompressionLevel
local CompressionMode = OPTIONS.CompressionMode
local __DEBUG_MODE = OPTIONS.__DEBUG_MODE
if __DEBUG_MODE and type(__DEBUG_MODE) ~= string.char(102,117,110,99,116,105,111,110) then
__DEBUG_MODE = warn
end
local LP_UserId, LP_Name, ANON_UserId, ANON_Name, Anonymizers
local function anonymize(raw, valueType)
local fn = Anonymizers and Anonymizers[valueType]
return fn and fn(raw) or raw
end
local function gsubCaseInsensitive(input, search, replacement)
local inputLower = string.lower(input)
search = string.lower(search)
if not string_find(inputLower, search) then
return input
end
local lastFinish = 0
local subStrings = {}
local search_len = #search
local input_len = #input
while search_len <= input_len - lastFinish do
local init = lastFinish + 1
local start, finish = string_find(inputLower, search, init)
if start == nil then
break
end
table.insert(subStrings, string.sub(input, init, start - 1))
lastFinish = finish
end
if lastFinish == 0 then
return input
end
table.insert(subStrings, string.sub(input, lastFinish + 1))
return table.concat(subStrings, replacement)
end
do
local anonymous = OPTIONS.Anonymous
local lp = service.Players.LocalPlayer
if anonymous and lp then
LP_UserId, LP_Name = lp.UserId, lp.Name
local istable = type(anonymous) == string.char(116,97,98,108,101)
ANON_UserId = istable and anonymous.UserId or 1
ANON_Name = istable and anonymous.Name or string.char(82,111,98,108,111,120)
local padded = ANON_Name
if #padded < #LP_Name then
padded ..= string.rep(string.char(95), #LP_Name - #padded)
elseif #padded > #LP_Name then
padded = string.sub(padded, 1, #LP_Name)
end
local function scrubName(raw)
return gsubCaseInsensitive(raw, LP_Name, ANON_Name)
end
local function scrubFixedWidth(raw)
return gsubCaseInsensitive(raw, LP_Name, padded)
end
local function scrubId(raw)
return raw == LP_UserId and ANON_UserId or raw
end
Anonymizers = {
string = scrubName,
BinaryString = scrubFixedWidth,
SharedString = scrubFixedWidth,
double = scrubId,
float = scrubId,
int = scrubId,
int64 = scrubId,
}
end
end
local FilePath = OPTIONS.FilePath
local SaveCacheInterval = OPTIONS.SaveCacheInterval
local Object = OPTIONS.Object
local IsModel = OPTIONS.IsModel
if Object and CustomOptions.IsModel == nil then
IsModel = true
end
local IgnoreDefaultProperties = OPTIONS.IgnoreDefaultProperties
local IgnoreNotArchivable = not OPTIONS.IgnoreNotArchivable
local IgnorePropertiesOfNotScriptsOnScriptsMode = OPTIONS.IgnorePropertiesOfNotScriptsOnScriptsMode
local old_gethiddenproperty
if OPTIONS.IgnoreSpecialProperties and gethiddenproperty then
old_gethiddenproperty = gethiddenproperty
gethiddenproperty = nil
end
local SaveNotCreatable = OPTIONS.SaveNotCreatable
local TreatUnionsAsParts = OPTIONS.TreatUnionsAsParts
local SharedBinaryStrings = OPTIONS.SharedBinaryStrings
local ToSaveList, ldecompile, placename, elapse_t, SaveNotCreatableWillBeEnabled, RecoveredScripts
if OPTIONS.ReadMe then
RecoveredScripts = {}
end
if Object == game then
OPTIONS.mode = string.char(102,117,108,108)
Object = nil
IsModel = nil
end
local function isLuaSourceContainer(instance)
return instance:IsA(string.char(76,117,97,83,111,117,114,99,101,67,111,110,116,97,105,110,101,114))
end
local function sanitizeFileName(str)
return string.sub(string.gsub(string.gsub(string.gsub(str, string.char(91,94,37,119,32,95,93), ""), string.char(32,43), string.char(32)), string.char(32,43,36), ""), 1, 240)
end
do
local mode = string.lower(OPTIONS.mode)
local tmp = table.clone(OPTIONS.ExtraInstances)
local PlaceName = game.PlaceId
pcall(function()
PlaceName ..= string.char(32) .. service.MarketplaceService:GetProductInfoAsync(PlaceName).Name
end)
if Object then
if mode == string.char(111,112,116,105,109,105,122,101,100) then mode = string.char(102,117,108,108)
end
for _, key in
{
string.char(73,115,111,108,97,116,101,76,111,99,97,108,80,108,97,121,101,114),
string.char(73,115,111,108,97,116,101,76,111,99,97,108,80,108,97,121,101,114,67,104,97,114,97,99,116,101,114),
string.char(73,115,111,108,97,116,101,80,108,97,121,101,114,115),
string.char(73,115,111,108,97,116,101,83,116,97,114,116,101,114,80,108,97,121,101,114),
string.char(78,105,108,73,110,115,116,97,110,99,101,115),
}
do
if CustomOptions_valid[key] == nil then
OPTIONS[key] = false
end
end
end
local filetype = OPTIONS.Binary and (IsModel and string.char(46,114,98,120,109) or string.char(46,114,98,120,108)) or (IsModel and string.char(46,114,98,120,109,120) or string.char(46,114,98,120,108,120))
if FilePath then
local hasExtension = string.match(FilePath, string.char(37,46,91,94,47,92,92,93,43,36)) ~= nil
placename = hasExtension and FilePath or (FilePath .. filetype)
elseif IsModel then
placename = sanitizeFileName(string.char(109,111,100,101,108,32) .. PlaceName .. string.char(32) .. (Object or tmp[1] or game):GetFullName())
else
placename = sanitizeFileName(string.char(112,108,97,99,101,32) .. PlaceName)
end
if FilePath then
elseif OPTIONS.AvoidFileOverwrite and isfile then
local counter = 0
local temp = placename
while isfile(temp .. filetype) do
counter += 1
temp = placename .. string.char(40) .. counter .. string.char(41)
end
placename = temp .. filetype
else
placename = placename .. filetype
end
if GLOBAL_ENV[placename] then return
end
GLOBAL_ENV[placename] = true
GLOBAL_ENV.USSI = nil
if mode ~= string.char(115,99,114,105,112,116,115) then
IgnorePropertiesOfNotScriptsOnScriptsMode = nil
end
local TempRoot = Object or game
if mode == string.char(102,117,108,108) then
if not Object then
local Children = TempRoot:GetChildren()
if 0 < #Children then
local tmp_dict = arrayToDict(tmp)
for _, child in Children do
if not tmp_dict[child] then
table.insert(tmp, child)
end
end
end
end
elseif mode == string.char(111,112,116,105,109,105,122,101,100) then local tmp_dict = arrayToDict(tmp)
for _, serviceName in
{
string.char(87,111,114,107,115,112,97,99,101),
string.char(80,108,97,121,101,114,115),
string.char(76,105,103,104,116,105,110,103),
string.char(77,97,116,101,114,105,97,108,83,101,114,118,105,99,101),
string.char(82,101,112,108,105,99,97,116,101,100,70,105,114,115,116),
string.char(82,101,112,108,105,99,97,116,101,100,83,116,111,114,97,103,101),
string.char(83,101,114,118,101,114,83,99,114,105,112,116,83,101,114,118,105,99,101), string.char(83,101,114,118,101,114,83,116,111,114,97,103,101), string.char(83,116,97,114,116,101,114,71,117,105),
string.char(83,116,97,114,116,101,114,80,97,99,107),
string.char(83,116,97,114,116,101,114,80,108,97,121,101,114),
string.char(84,101,97,109,115),
string.char(83,111,117,110,100,83,101,114,118,105,99,101),
string.char(67,104,97,116),
string.char(84,101,120,116,67,104,97,116,83,101,114,118,105,99,101),
string.char(76,111,99,97,108,105,122,97,116,105,111,110,83,101,114,118,105,99,101), string.char(74,111,105,110,116,115,83,101,114,118,105,99,101),
}
do
local _service = game:FindService(serviceName)
if _service and not tmp_dict[_service] then
table.insert(tmp, _service)
end
end
elseif mode == string.char(115,99,114,105,112,116,115) then
local unique = {}
for _, instance in TempRoot:GetDescendants() do
if isLuaSourceContainer(instance) then
local Parent = instance.Parent
while Parent and Parent ~= TempRoot do
instance = instance.Parent
Parent = instance.Parent
end
if Parent then
unique[instance] = true
end
end
end
for instance in unique do
table.insert(tmp, instance)
end
end
ToSaveList = tmp
if Object then
table.insert(ToSaveList, 1, Object)
end
end
local IsolateLocalPlayer = OPTIONS.IsolateLocalPlayer
local IsolateLocalPlayerCharacter = OPTIONS.IsolateLocalPlayerCharacter
local IsolatePlayers = OPTIONS.IsolatePlayers
local IsolateStarterPlayer = OPTIONS.IsolateStarterPlayer
local NilInstances = OPTIONS.NilInstances
if IsolatePlayers and IsolateLocalPlayer then
IsolateLocalPlayer = false
end
local function GetLocalPlayer()
return service.Players.LocalPlayer
or service.Players:GetPropertyChangedSignal(string.char(76,111,99,97,108,80,108,97,121,101,114)):Wait()
or service.Players.LocalPlayer
end
local function get_size_format()
local Size
for i, unit in
{
string.char(66),
string.char(75,66),
string.char(77,66),
string.char(71,66),
string.char(84,66),
}
do
if totalsize < 0x400 ^ i then
Size = math.floor(totalsize / (0x400 ^ (i - 1)) * 10) / 10 .. string.char(32) .. unit
break
end
end
return Size
end
local RunService = service.RunService
local function wait_for_render()
RunService.RenderStepped:Wait()
end
local IsLoading, LoadingText, LoadingThread = false
local function ensureSpinner()
if LoadingThread then
return
end
LoadingThread = task.spawn(function()
local chars = { string.char(124), string.char(47), string.char(8212), string.char(92,92) }
local i = 0
while true do
while not IsLoading do
task.wait()
end
while IsLoading do
i = i % #chars + 1
if StatusText and LoadingText then
StatusText.Text = LoadingText .. string.char(32) .. chars[i]
end
task.wait(0.25)
end
end
end)
end
local function run_with_loading(text, keepStatus, waitForRender, taskFunction, ...)
local previousStatus
if StatusText then
if keepStatus then
previousStatus = StatusText.Text
end
LoadingText = text
IsLoading = true
ensureSpinner()
if waitForRender then
wait_for_render()
end
end
local result = { taskFunction(...) }
if StatusText then
IsLoading = false
if previousStatus then
StatusText.Text = previousStatus
end
end
return unpack(result)
end
local function makeTimeoutHandler(timeout, f, timeout_return)
if timeout < 0 then
return function(...)
return pcall(f, ...)
end
end
local worker
local pendingJob
local function spawnWorker()
return task.spawn(function()
while true do
while not pendingJob do
task.wait()
end
local job = pendingJob
pendingJob = nil
local ok, result = pcall(f, unpack(job.args))
if job.isCancelled then
return end
task.cancel(job.timeoutThread)
local thread = job.thread
while coroutine.status(thread) ~= string.char(115,117,115,112,101,110,100,101,100) do
task.wait()
end
coroutine.resume(thread, ok, result)
end
end)
end
return function(...)
local thread = coroutine.running()
local job = {
thread = thread,
args = { ... },
}
job.timeoutThread = task.delay(timeout, function()
job.isCancelled = true
worker = nil coroutine.resume(thread, nil, timeout_return)
end)
if not worker then
worker = spawnWorker()
end
pendingJob = job
return coroutine.yield()
end
end
local decompileIgnoreMap = {}
local DecompileJobless = OPTIONS.DecompileJobless
if DecompileJobless then
OPTIONS.scriptcache = true
end
local ScriptCache = OPTIONS.scriptcache and getscriptbytecode
local ldeccache = GLOBAL_ENV.USSI_scriptcache
if ScriptCache and not ldeccache then
ldeccache = {}
GLOBAL_ENV.USSI_scriptcache = ldeccache
end
local getbytecode
if getscriptbytecode then
getbytecode = makeTimeoutHandler(OPTIONS.BytecodeTimeout, getscriptbytecode) end
local SaveBytecode
if OPTIONS.SaveBytecode and getscriptbytecode then
SaveBytecode = function(script)
local s, bytecode = getbytecode(script)
if s and bytecode and bytecode ~= "" then
return string.char(45,45,32,66,121,116,101,99,111,100,101,32,40,66,97,115,101,54,52,41,58,92,110,45,45,32) .. base64encode(bytecode) .. string.char(92,110,92,110)
end
end
end
if not OPTIONS.Decompile then
ldecompile = function()
return string.char(45,45,32,68,101,99,111,109,112,105,108,105,110,103,32,105,115,32,100,105,115,97,98,108,101,100)
end
elseif decompile then
local decomp = makeTimeoutHandler(OPTIONS.DecompileTimeout, decompile, string.char(68,101,99,111,109,112,105,108,101,114,32,116,105,109,101,100,32,111,117,116))
ldecompile = function(script)
local bytecode
if ScriptCache then
local s
s, bytecode = getbytecode(script)
local cached
if s then
if not bytecode or bytecode == "" then
return string.char(45,45,32,84,104,101,32,83,99,114,105,112,116,32,105,115,32,69,109,112,116,121)
end
cached = ldeccache[bytecode]
else
bytecode = nil
end
if cached then
if __DEBUG_MODE then
__DEBUG_MODE(string.char(70,111,117,110,100,32,105,110,32,67,97,99,104,101), script:GetFullName())
end
return cached
end
else
if DecompileJobless then
return string.char(45,45,32,78,111,116,32,102,111,117,110,100,32,105,110,32,97,108,114,101,97,100,121,32,100,101,99,111,109,112,105,108,101,100,32,83,99,114,105,112,116,67,97,99,104,101)
end
end
local ok, result = run_with_loading(string.char(68,101,99,111,109,112,105,108,105,110,103,32) .. script.Name, true, nil, decomp, script)
if not result then
ok, result = false, string.char(69,109,112,116,121,32,79,117,116,112,117,116)
end
local output
if ok then
result = string.gsub(result, string.char(92,48), string.char(92,92,48)) output = result
else
output = string.char(45,45,91,91,32,70,97,105,108,101,100,32,116,111,32,100,101,99,111,109,112,105,108,101,46,32,82,101,97,115,111,110,58,92,110) .. (result or "") .. string.char(92,110,93,93)
end
if ScriptCache and bytecode then ldeccache[bytecode] = output if __DEBUG_MODE then
__DEBUG_MODE(string.char(67,97,99,104,101,100), script:GetFullName())
end
end
return output
end
else
ldecompile = function()
return string.char(45,45,32,89,111,117,114,32,69,120,101,99,117,116,111,114,32,100,111,101,115,32,78,79,84,32,104,97,118,101,32,97,32,68,101,99,111,109,112,105,108,101,114)
end
end
local function filterLinkedSource(str)
local o, r = pcall(service.HttpService.JSONDecode, service.HttpService, str)
if o and r.errors then
return
end
return true
end
local function sourceFor(instance, ldIgnoring)
if ldIgnoring then
return string.char(45,45,32,73,103,110,111,114,101,100)
end
local value
local should_decompile = true
local LinkedSource
local o, LinkedSource_Url = pcall(index, instance, string.char(76,105,110,107,101,100,83,111,117,114,99,101)) if not o then
LinkedSource_Url = ""
end
local hasLinkedSource = LinkedSource_Url ~= ""
local LinkedSource_type
if hasLinkedSource then
local Path = instance:GetFullName()
if RecoveredScripts then
table.insert(RecoveredScripts, Path)
end
LinkedSource = string.match(LinkedSource_Url, string.char(37,119,43,36)) if LinkedSource then
if ScriptCache then
local cached = ldeccache[LinkedSource]
if cached then
value = cached
should_decompile = nil
end
end
if should_decompile then
if DecompileJobless then
value = string.char(45,45,32,78,111,116,32,102,111,117,110,100,32,105,110,32,76,105,110,107,101,100,83,111,117,114,99,101,32,83,99,114,105,112,116,67,97,99,104,101)
should_decompile = nil
end
LinkedSource_type = string.find(LinkedSource, string.char(37,97)) and string.char(104,97,115,104) or string.char(105,100)
local asset = LinkedSource_type .. string.char(61) .. LinkedSource
local ok, source = pcall(function()
return game:HttpGet(string.char(104,116,116,112,115,58,47,47,97,115,115,101,116,100,101,108,105,118,101,114,121,46,114,111,112,114,111,120,121,46,99,111,109,47,118,49,47,97,115,115,101,116,47,63) .. asset)
end)
if ok and filterLinkedSource(source) then
if ScriptCache then
ldeccache[LinkedSource] = source
end
value = source
should_decompile = nil
end
end
else warn(string.char(70,65,73,76,69,68,32,84,79,32,69,88,84,82,65,67,84,32,76,73,78,75,69,68,83,79,85,82,67,69,32,40,79,80,69,78,32,65,32,71,73,84,72,85,66,32,73,83,83,85,69,41,58,32), instance:GetFullName(), LinkedSource_Url)
end
end
if should_decompile then
local isLocalScript = instance:IsA(string.char(76,111,99,97,108,83,99,114,105,112,116))
if
isLocalScript and instance.RunContext == Enum.RunContext.Server
or not isLocalScript and instance:IsA(string.char(83,99,114,105,112,116)) and instance.RunContext ~= Enum.RunContext.Client
then
value = string.char(45,45,32,91,70,105,108,116,101,114,105,110,103,69,110,97,98,108,101,100,93,32,83,101,114,118,101,114,32,83,99,114,105,112,116,115,32,97,114,101,32,73,77,80,79,83,83,73,66,76,69,32,116,111,32,115,97,118,101) else
value = ldecompile(instance)
if SaveBytecode then
local output = SaveBytecode(instance)
if output then
value = output .. value
end
end
end
end
value = string.char(45,45,32,83,97,118,101,100,32,98,121,32,67,79,80,89,77,65,80,95,72,85,66,32,91,106,111,105,110,32,110,111,119,93,32,104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,103,103,47,97,56,114,117,57,78,118,101,78,92,110,92,110)
.. (hasLinkedSource and string.char(45,45,32,79,114,105,103,105,110,97,108,32,83,111,117,114,99,101,58,32,104,116,116,112,115,58,47,47,97,115,115,101,116,100,101,108,105,118,101,114,121,46,114,111,98,108,111,120,46,99,111,109,47,118,49,47,97,115,115,101,116,47,63) .. (LinkedSource_type or string.char(105,100)) .. string.char(61) .. (LinkedSource or LinkedSource_Url) .. string.char(92,110,92,110) or "")
.. value
return value
end
local function replaceClassName(instance, InstanceName, ClassName)
local InstanceOverride = InstancesOverrides[instance]
if InstanceOverride then
return InstanceOverride
end
if InstanceName ~= ClassName then InstanceOverride = { Properties = { Name = string.char(91) .. ClassName .. string.char(93,32) .. InstanceName } }
InstancesOverrides[instance] = InstanceOverride
end
return InstanceOverride
end
local function refIsInvalid(target, propName, valueType)
if not SaveNotCreatableWillBeEnabled or not target then
return false
end
local fix = NotCreatableFixes[target.ClassName]
return fix ~= nil and (propName == string.char(80,108,97,121,101,114,84,111,72,105,100,101,70,114,111,109) or valueType ~= string.char(73,110,115,116,97,110,99,101) and valueType ~= fix)
end
local function nilIsValid(category, optional)
return optional ~= nil or category == string.char(67,108,97,115,115)
end
local function filterPropVal(result, propertyName, category, optional) if result == nil then
return not nilIsValid(category, optional)
end
return result == string.char(99,97,110,39,116,32,103,101,116,32,118,97,108,117,101)
or type(result) == string.char(115,116,114,105,110,103)
and (category == string.char(69,110,117,109) or string_find(result, string.char(85,110,97,98,108,101,32,116,111,32,103,101,116,32,112,114,111,112,101,114,116,121,32) .. propertyName))
end
local GHP_STATE_FILE = USSI_FOLDER .. string.char(71,72,80,95,83,84,65,84,69,46,106,115,111,110)
local GHPDatatypeState = {}
local GHPPersisted = {}
local GHPVersionKey
do
local execName, execVersion = string.char(85,78,75,78,79,87,78), string.char(48)
if identify_executor then
local ok, name, ver = pcall(identify_executor)
if ok and name then
execName, execVersion = name, ver or string.char(48)
end
end
GHPVersionKey = sanitizeFileName(execName)
.. string.char(95)
.. sanitizeFileName(execVersion)
.. string.char(95)
.. sanitizeFileName(FULL_VERSION)
if readfile then
local ok, decoded = pcall(function()
return service.HttpService:JSONDecode(readfile(GHP_STATE_FILE))
end)
if ok and type(decoded) == string.char(116,97,98,108,101) and type(decoded[GHPVersionKey]) == string.char(116,97,98,108,101) then
GHPPersisted = decoded[GHPVersionKey]
end
end
end
local function saveGHPState()
if not writefile then
return
end
pcall(writefile, GHP_STATE_FILE, service.HttpService:JSONEncode({ [GHPVersionKey] = GHPPersisted }))
end
local function ghpDatatypeAllowed(valueType)
local state = GHPDatatypeState[valueType]
if state ~= nil then
return state
end
local persisted = GHPPersisted[valueType]
if persisted == string.char(111,107) then
state = true
elseif persisted == string.char(102,97,105,108,101,100) or persisted == string.char(116,101,115,116,105,110,103) then
state = false
else
GHPPersisted[valueType] = string.char(116,101,115,116,105,110,103)
saveGHPState()
state = true
end
GHPDatatypeState[valueType] = state
return state
end
local function ghpDatatypeReport(valueType, ok)
local wantState = ok and string.char(111,107) or string.char(102,97,105,108,101,100)
if GHPPersisted[valueType] == wantState then
return
end
GHPPersisted[valueType] = wantState
GHPDatatypeState[valueType] = ok
saveGHPState()
end
local function readProperty(instance, property)
local raw = __BREAK
local PropertyName, Special, Category, ValueType, Optional =
property.Name, property.Special, property.Category, property.ValueType, property.Optional
local InstanceOverride = InstancesOverrides[instance]
if InstanceOverride then
local PropertiesOverride = InstanceOverride.Properties
if PropertiesOverride then
local PropertyOverride = PropertiesOverride[PropertyName]
if PropertyOverride ~= nil then
return anonymize(PropertyOverride, ValueType)
end
end
end
if ValueType == string.char(80,114,111,116,101,99,116,101,100,83,116,114,105,110,103) and PropertyName == string.char(83,111,117,114,99,101) and isLuaSourceContainer(instance) then
return sourceFor(instance, decompileIgnoreMap[instance])
end
local CanRead = property.CanRead
if CanRead ~= false then
local GHPKey = (Category == string.char(69,110,117,109) or Category == string.char(67,108,97,115,115)) and Category or ValueType
if Special then
if gethiddenproperty and ghpDatatypeAllowed(GHPKey) then
local ok, result = pcall(gethiddenproperty, instance, PropertyName)
if ok then
raw = result
end
local filtered = filterPropVal(raw, PropertyName, Category, Optional)
local realFailure = filtered and not (result == nil and nilIsValid(Category, Optional))
ghpDatatypeReport(GHPKey, ok and not realFailure)
if filtered then
if realFailure then
if __DEBUG_MODE then
__DEBUG_MODE(string.char(70,105,108,116,101,114,101,100), PropertyName)
end
property.CanRead = false
end
raw = __BREAK
end
end
elseif CanRead then
raw = instance[PropertyName]
else
local ok, result = pcall(index, instance, PropertyName)
if ok then
raw = result
elseif gethiddenproperty and ghpDatatypeAllowed(ValueType) then
ok, result = pcall(gethiddenproperty, instance, PropertyName)
ghpDatatypeReport(ValueType, ok and not filterPropVal(result, PropertyName, Category, Optional))
if ok then
raw = result
property.Special = true
end
end
property.CanRead = ok
if not ok or filterPropVal(raw, PropertyName, Category, Optional) then
raw = __BREAK
end
end
if raw ~= __BREAK then
return anonymize(raw, ValueType)
end
end
local GHPFFailed, Fallback = property.GHPFFailed, property.Fallback
if GHPFFailed and not Fallback then
return __BREAK
end
if not GHPFFailed then
local ok, result = pcall(gethiddenproperty_fallback, instance, PropertyName)
if result == nil and not nilIsValid(Category, Optional) then
ok = nil
end
if ok then
return anonymize(result, ValueType)
end
GHPFFailed = true
property.GHPFFailed = true
end
if GHPFFailed and Fallback then
local ok, result = pcall(Fallback, instance)
if ok then
return anonymize(result, ValueType)
end
property.Fallback = nil
if __DEBUG_MODE then
__DEBUG_MODE(string.char(70,105,120,32,70,97,105,108,101,100), PropertyName, result)
end
end
return __BREAK
end
local function ReturnItem(className, instance)
return string.char(60,73,116,101,109,32,99,108,97,115,115,61,34) .. className .. string.char(34,32,114,101,102,101,114,101,110,116,61,34) .. getRef(instance) .. string.char(34,62,60,80,114,111,112,101,114,116,105,101,115,62) end
local function ReturnProperty(tag, propertyName, value)
return string.char(60) .. tag .. string.char(32,110,97,109,101,61,34) .. propertyName .. string.char(34,62) .. value .. string.char(60,47) .. tag .. string.char(62)
end
local function ReturnValueAndTag(raw, valueType, encoder)
local value, tag = (encoder or XML_Encoders[valueType])(raw)
return value, tag or valueType
end
local function InheritsFix(fixes, className, instance)
local Fix = fixes[className]
if Fix then
return Fix
elseif Fix == nil then
for class_name, fix in fixes do
if instance:IsA(class_name) then
return fix
end
end
end
end
local function GetInheritedProps(className)
local cached = inheritedProperties[className]
if cached then
return cached
end
local prop_list = {}
local layer = ClassList[className]
while layer do
local layer_props = layer.Properties
table.move(layer_props, 1, #layer_props, #prop_list + 1, prop_list)
layer = ClassList[layer.Superclass]
end
inheritedProperties[className] = prop_list
return prop_list
end
local function collect(roots)
local ctx = {
entries = {},
classList = {},
ordered = {},
refs = {},
instCount = 0,
instTypeCount = 0,
}
local entries, classList = ctx.entries, ctx.classList
local ordered, refs = ctx.ordered, ctx.refs
local function recur(instance, parent, ldIgnore)
if entries[instance] then
return end
local override = InstancesOverrides[instance]
local tagOverride = override and override.__ClassName
local virtual = override and override.__Virtual
local class = virtual or instance.ClassName
local name = virtual and override.Properties.Name or instance.Name
local unknownTag, propClass, skipEntirely
local own = DecompileIgnore[instance]
if own == nil then
local byClass = DecompileIgnore[class]
if byClass ~= nil then
own = byClass == true or byClass[name]
end
end
if own == true then
ldIgnore = true
elseif own == false then
ldIgnore = string.char(115,101,108,102)
end
if ldIgnore then
decompileIgnoreMap[instance] = true
end
if not tagOverride then
if IgnoreNotArchivable and not instance.Archivable then
return
end
skipEntirely = IgnoreList[instance]
if skipEntirely then
return
end
local onIgnoredList = IgnoreList[class]
if onIgnoredList and (onIgnoredList == true or onIgnoredList[name]) then
return
end
local fix = NotCreatableFixes[class]
if fix then
if not SaveNotCreatable then
return end
class, override = fix, replaceClassName(instance, name, class)
elseif TreatUnionsAsParts and instance:IsA(string.char(80,97,114,116,79,112,101,114,97,116,105,111,110)) then
class, override = string.char(80,97,114,116), replaceClassName(instance, name, class)
propClass = string.char(66,97,115,101,80,97,114,116)
elseif not ClassList[class] then
if __DEBUG_MODE then
__DEBUG_MODE(string.char(67,108,97,115,115,32,110,111,116,32,70,111,117,110,100), class)
end
unknownTag, class = class, string.char(70,111,108,100,101,114)
end
end
local e = {
tag = unknownTag or tagOverride or class,
class = tagOverride or class,
propClass = propClass or class,
override = override,
propsOnly = virtual ~= nil or (override and override.__Synthetic),
virtual = virtual ~= nil,
parent = parent,
}
entries[instance] = e
ctx.instCount += 1
refs[instance] = ctx.instCount - 1
local bucket = e.tag
if e.propsOnly then
bucket ..= string.char(92,48) .. e.propClass .. string.char(92,48,112,114,111,112,115,79,110,108,121)
elseif e.propClass ~= bucket then
bucket ..= string.char(92,48) .. e.propClass
end
local list = classList[bucket]
if not list then
list = {}
classList[bucket] = list
ctx.instTypeCount += 1
end
list[#list + 1] = instance
local kids
if skipEntirely ~= false then
local children = (override and override.__Children) or (not virtual and instance:GetChildren())
kids = table.create(#children)
for _, child in children do
recur(child, instance, ldIgnore == true and true or nil)
if entries[child] then
kids[#kids + 1] = child
end
end
end
e.children = kids or {}
ordered[#ordered + 1] = instance
end
local roots_kept = table.create(#roots)
for _, root in roots do
recur(root)
if entries[root] then
roots_kept[#roots_kept + 1] = root
end
end
ctx.roots = roots_kept
return ctx
end
local function newVirtual(className, properties, children)
local node = {}
InstancesOverrides[node] = {
__ClassName = className,
__Virtual = className,
__Children = children or {},
Properties = properties,
}
return node
end
local pendingExtras = {}
local function register_extra(name, instanceOrTable, saveProps, customClassName, source)
customClassName = customClassName or string.char(70,111,108,100,101,114)
local properties = { Name = name, Source = source }
local extra = { customClassName = customClassName, properties = properties }
if instanceOrTable and saveProps and type(instanceOrTable) ~= string.char(116,97,98,108,101) then
local existing = InstancesOverrides[instanceOrTable]
if existing then
existing.__ClassName = customClassName
existing.Properties = properties
else
InstancesOverrides[instanceOrTable] = {
__ClassName = customClassName,
Properties = properties,
}
end
extra.roots = { instanceOrTable }
else
local children
if instanceOrTable then
children = type(instanceOrTable) == string.char(116,97,98,108,101) and instanceOrTable or instanceOrTable:GetChildren()
end
extra.roots = { newVirtual(customClassName, properties, children) }
end
pendingExtras[#pendingExtras + 1] = extra
return extra
end
local function readAll(objs, prop)
local n = #objs
local vals = table.create(n)
for i = 1, n do
local raw = readProperty(objs[i], prop)
if raw == __BREAK then
return nil, i
end
vals[i] = raw
end
return vals
end
local function buildChunk(name, chunkBuf, compress)
local uncompressedLen = chunkBuf.len
local head = StreamBuffer.new(16)
head:writestring(name)
if compress then
local dataStr = compress(chunkBuf:tostring())
if dataStr and #dataStr < uncompressedLen then
head:writeu32(#dataStr)
head:writeu32(uncompressedLen)
head:writeu32(0) return { buf = head.buf, len = head.len, str = dataStr }
end
end
head:writeu32(0) head:writeu32(uncompressedLen)
head:writeu32(0) return {
buf = head.buf,
len = head.len,
tailBuf = chunkBuf.buf,
tailLen = uncompressedLen,
}
end
local function emitBinary(ctx)
local compress = CompressionMode == string.char(122,115,116,100)
and function(raw)
return zstdcompress(raw, CompressionLevel)
end
or CompressionMode == string.char(108,122,52) and lz4compress
or nil
local entries, classList = ctx.entries, ctx.classList
local refs, ordered = ctx.refs, ctx.ordered
local instCount, instTypeCount = ctx.instCount, ctx.instTypeCount
local chunks = {}
local lastStatus = 0
local function emit(chunk)
chunks[#chunks + 1] = chunk
totalsize += chunk.len + (chunk.str and #chunk.str or chunk.tailLen or 0)
if StatusText then
local now = os.clock()
if now - lastStatus > 1 then
lastStatus = now
StatusText.Text = string.char(83,97,118,105,110,103,46,46,32,83,105,122,101,58,32) .. get_size_format()
wait_for_render()
end
end
end
do
local header = StreamBuffer.new(32)
header:writestring(string.char(92,54,48,92,49,49,52,92,49,49,49,92,57,56,92,49,48,56,92,49,49,49,92,49,50,48,92,51,51,92,49,51,55,92,50,53,53,92,49,51,92,49,48,92,50,54,92,49,48,92,48,92,48)) header:writei32(instTypeCount)
header:writei32(instCount)
header:fill(0, 8) emit({ buf = header.buf, len = header.len })
end
if IsModel then
local metaBuf = StreamBuffer.new(64)
metaBuf:writeu32(1)
metaBuf:writeLenString(string.char(69,120,112,108,105,99,105,116,65,117,116,111,74,111,105,110,116,115))
metaBuf:writeLenString(string.char(116,114,117,101))
emit(buildChunk(string.char(77,69,84,65), metaBuf, compress))
end
local sstrSlot = #chunks + 1
local sharedStringCtx = { count = 0, order = {}, hashes = {} }
local classId = 0
local deferredBuckets
local function encode_class_bucket(objs)
local n = #objs
local entry = entries[objs[1]]
local class = entry.class
local instBuf = StreamBuffer.new(64 + 4 * n)
instBuf:writeu32(classId)
instBuf:writeLenString(class)
local classInfo = ClassList[class]
local isService = classInfo and classInfo.Service
instBuf:writeu8(isService and 1 or 0)
instBuf:writeu32(n)
writeRefPlane(instBuf, n, instBuf:allocRegion(4 * n), function(i)
return refs[objs[i]]
end)
if isService then
for _ = 1, n do
instBuf:writeu8(1)
end
end
emit(buildChunk(string.char(73,78,83,84), instBuf, compress))
local skipProps = IgnorePropertiesOfNotScriptsOnScriptsMode
and not entry.propsOnly
and not isLuaSourceContainer(objs[1])
if entry.propsOnly then
for propName in entry.override.Properties do
local isSource = propName == string.char(83,111,117,114,99,101)
local buf = StreamBuffer.new(64 + n * 16)
buf:writeu32(classId)
buf:writeLenString(propName)
buf:writeu8(isSource and Type_Ids.ProtectedString or Type_Ids.string)
for i = 1, n do
local value = entries[objs[i]].override.Properties[propName]
if type(value) == string.char(102,117,110,99,116,105,111,110) then
value = value() end
buf:writeLenString(value or "")
end
emit(buildChunk(string.char(80,82,79,80), buf, not isSource and compress or nil)) end
elseif not skipProps then
for _, prop in GetInheritedProps(entry.propClass) do
local propName = prop.Name
if IgnoreProperties[propName] then
continue
end
local valueType = prop.ValueType
if SharedBinaryStrings and valueType == string.char(66,105,110,97,114,121,83,116,114,105,110,103) then
valueType = string.char(83,104,97,114,101,100,83,116,114,105,110,103)
end
local refCtxArg = nil
if prop.Category == string.char(69,110,117,109) then
valueType = string.char(69,110,117,109)
elseif prop.Category == string.char(67,108,97,115,115) then
valueType = string.char(82,101,102,101,114,101,110,116)
refCtxArg = refs
elseif valueType == string.char(67,111,110,116,101,110,116) then
refCtxArg = refs
end
local encoder = Binary_Encoders[valueType]
local typeId = Type_Ids[valueType]
if typeId == Type_Ids.SharedString then
refCtxArg = sharedStringCtx
end
local vals, failedAt = readAll(objs, prop)
if not vals then
if __DEBUG_MODE then
__DEBUG_MODE(string.char(80,82,79,80,32,100,114,111,112,112,101,100), class, propName, string.char(110,61) .. #objs, string.char(102,97,105,108,101,100,32,97,116,32) .. failedAt)
end
continue
end
if encoder and typeId then
if prop.Category == string.char(67,108,97,115,115) then
for i = 1, n do
if refIsInvalid(vals[i], propName, valueType) then
vals[i] = nil
end
end
end
local propBuf = StreamBuffer.new(128 + #objs * 4)
propBuf:writeu32(classId)
propBuf:writeLenString(propName)
propBuf:writeu8(typeId)
encoder(propBuf, vals, #objs, refCtxArg)
emit(buildChunk(string.char(80,82,79,80), propBuf, compress))
else
warn(string.char(85,78,83,85,80,80,79,82,84,69,68,32,66,73,78,65,82,89,32,84,89,80,69,32,40,79,80,69,78,32,65,32,71,73,84,72,85,66,32,73,83,83,85,69,41,58,32), propName, valueType)
end
end
end
classId += 1
end
for _, objs in classList do
if entries[objs[1]].deferLast then
deferredBuckets = deferredBuckets or {}
table.insert(deferredBuckets, objs)
else
encode_class_bucket(objs)
end
end
if deferredBuckets then
for _, objs in deferredBuckets do
encode_class_bucket(objs)
end
end
if sharedStringCtx.count > 0 then
local sstrBuf = StreamBuffer.new(64 + sharedStringCtx.count * 32)
sstrBuf:writeu32(0) sstrBuf:writeu32(sharedStringCtx.count)
for i = 1, sharedStringCtx.count do
sstrBuf:fill(0, 16) sstrBuf:writeLenString(sharedStringCtx.order[i])
end
local chunk = buildChunk(string.char(83,83,84,82), sstrBuf, compress)
table.insert(chunks, sstrSlot, chunk)
totalsize += chunk.len + (chunk.str and #chunk.str or chunk.tailLen or 0)
end
do
local prntBuf = StreamBuffer.new(16 + instCount * 8)
prntBuf:writeu8(0) prntBuf:writeu32(instCount)
local objBase = prntBuf:allocRegion(4 * instCount)
local parBase = prntBuf:allocRegion(4 * instCount)
writeRefPlane(prntBuf, instCount, objBase, function(i)
return refs[ordered[i]]
end)
writeRefPlane(prntBuf, instCount, parBase, function(i)
local par = entries[ordered[i]].parent
return (par and refs[par]) or -1
end)
emit(buildChunk(string.char(80,82,78,84), prntBuf, compress))
end
do
local endBuf = StreamBuffer.new(16)
endBuf:writestring(string.char(60,47,114,111,98,108,111,120,62))
emit(buildChunk(string.char(69,78,68,92,48), endBuf, nil))
end
local out = table.create(#chunks)
for i, c in chunks do
local part = buffer.readstring(c.buf, 0, c.len)
if c.str then
part ..= c.str
elseif c.tailBuf then
part ..= buffer.readstring(c.tailBuf, 0, c.tailLen)
end
out[i] = part
end
return out
end
local function emitXML(ctx)
local chunks = table.create(1)
local savebuffer, savebuffer_size = {}, 1
local header =
table.concat({string.char(60,33,45,45,32,83,97,118,101,100,32,98,121,32,67,79,80,89,77,65,80,95,72,85,66,32,91,106,111,105,110,32,110,111,119,93,32,104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,103,103,47,97,56,114,117,57,78,118,101,78,32,45,45,62,60,114,111,98,108,111,120,32,118,101,114),string.char(115,105,111,110,61,34,52,34,62)})
local function save_cache()
local savestr = table.concat(savebuffer)
local savestr_len = #savestr
totalsize += savestr_len
table.insert(chunks, savestr)
table.clear(savebuffer)
savebuffer_size = 1
if StatusText then
StatusText.Text = string.char(83,97,118,105,110,103,46,46,32,83,105,122,101,58,32) .. get_size_format()
end
wait_for_render() end
local function save_hierarchy(hierarchy, ctx)
local entries = ctx.entries
for _, instance in hierarchy do
local entry = entries[instance]
if not entry then
continue end
savebuffer[savebuffer_size] = ReturnItem(entry.tag, instance)
savebuffer_size += 1
if entry.propsOnly then
for propName, value in entry.override.Properties do
if type(value) == string.char(102,117,110,99,116,105,111,110) then
value = value() end
if value ~= nil then
if propName == string.char(83,111,117,114,99,101) then
savebuffer[savebuffer_size] =
ReturnProperty(string.char(80,114,111,116,101,99,116,101,100,83,116,114,105,110,103), propName, XML_Encoders.ProtectedString(value))
else
savebuffer[savebuffer_size] =
ReturnProperty(string.char(115,116,114,105,110,103), propName, XML_Encoders.string(value))
end
savebuffer_size += 1
end
end
elseif not (IgnorePropertiesOfNotScriptsOnScriptsMode and not isLuaSourceContainer(instance)) then
local default_instance, new_def_inst
if IgnoreDefaultProperties then
default_instance = defaultInstances[entry.class]
if not default_instance then
local Class = ClassList[entry.class]
if not Class.NotCreatable then
local ok, result = pcall(Instance.new, entry.class) if ok then
new_def_inst = result
default_instance = {}
defaultInstances[entry.class] = default_instance
else
Class.NotCreatable = true
if __DEBUG_MODE then
__DEBUG_MODE(string.char(70,97,105,108,101,100,32,116,111,32,99,114,101,97,116,101,32,100,101,102,97,117,108,116,32,73,110,115,116,97,110,99,101), entry.class, result)
end
end
elseif __DEBUG_MODE then
__DEBUG_MODE(string.char(85,110,97,98,108,101,32,116,111,32,99,114,101,97,116,101,32,100,101,102,97,117,108,116,32,73,110,115,116,97,110,99,101,32,40,78,111,116,67,114,101,97,116,97,98,108,101,41), entry.class)
end
end
end
for _, Property in GetInheritedProps(entry.propClass) do
local PropertyName = Property.Name
if IgnoreProperties[PropertyName] then
continue
end
local ValueType = Property.ValueType
local Category, Optional = Property.Category, Property.Optional
local raw
raw = readProperty(instance, Property)
if raw == __BREAK then
continue
end
if
default_instance
and Property.CanRead
and not Property.Special
and ValueType ~= string.char(80,114,111,116,101,99,116,101,100,83,116,114,105,110,103)
then
if new_def_inst then
default_instance[PropertyName] = index(new_def_inst, PropertyName)
end
if default_instance[PropertyName] == raw then
continue
end
end
if SharedBinaryStrings and ValueType == string.char(66,105,110,97,114,121,83,116,114,105,110,103) then
ValueType = string.char(83,104,97,114,101,100,83,116,114,105,110,103)
end
local tag, value
if Category == string.char(67,108,97,115,115) then
tag = string.char(82,101,102)
if raw and not refIsInvalid(raw, PropertyName, ValueType) then
value = getRef(raw)
else
value = string.char(110,117,108,108)
end
elseif Category == string.char(69,110,117,109) then
value, tag = XML_Encoders.EnumItem(raw)
else
local encoder = XML_Encoders[ValueType]
if encoder then
value, tag = ReturnValueAndTag(raw, ValueType, encoder)
elseif Optional then
encoder = XML_Encoders[Optional]
if encoder then
if raw == nil then
continue
end
value, tag = ReturnValueAndTag(raw, ValueType, encoder)
end
end
end
if tag then
savebuffer[savebuffer_size] = ReturnProperty(tag, PropertyName, value)
savebuffer_size += 1
else
warn(string.char(85,78,83,85,80,80,79,82,84,69,68,32,88,77,76,32,84,89,80,69,32,40,79,80,69,78,32,65,32,71,73,84,72,85,66,32,73,83,83,85,69,41,58,32), PropertyName, ValueType)
end
end
end
savebuffer[savebuffer_size] = string.char(60,47,80,114,111,112,101,114,116,105,101,115,62)
savebuffer_size += 1
if SaveCacheInterval < savebuffer_size then
save_cache()
end
local children = entry.children
if #children ~= 0 then
save_hierarchy(children, ctx)
end
savebuffer[savebuffer_size] = string.char(60,47,73,116,101,109,62)
savebuffer_size += 1
end
end
if IsModel then
header ..= string.char(60,77,101,116,97,32,110,97,109,101,61,34,69,120,112,108,105,99,105,116,65,117,116,111,74,111,105,110,116,115,34,62,116,114,117,101,60,47,77,101,116,97,62)
end
savebuffer[savebuffer_size] = header
savebuffer_size += 1
save_hierarchy(ctx.mainRoots, ctx)
for _, extra in pendingExtras do
save_hierarchy(extra.collectedRoots, ctx)
end
do
local tmp = { string.char(60,83,104,97,114,101,100,83,116,114,105,110,103,115,62) }
for value, id in sharedStrings do
table.insert(tmp, string.char(60,83,104,97,114,101,100,83,116,114,105,110,103,32,109,100,53,61,34) .. id .. string.char(34,62) .. value .. string.char(60,47,83,104,97,114,101,100,83,116,114,105,110,103,62))
end
if 1 < #tmp then
savebuffer[savebuffer_size] = table.concat(tmp)
savebuffer_size += 1
savebuffer[savebuffer_size] = string.char(60,47,83,104,97,114,101,100,83,116,114,105,110,103,115,62)
savebuffer_size += 1
end
end
savebuffer[savebuffer_size] = string.char(60,47,114,111,98,108,111,120,62,60,33,45,45,32,83,97,118,101,100,32,98,121,32,67,79,80,89,77,65,80,95,72,85,66,32,91,106,111,105,110,32,110,111,119,93,32,104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,103,103,47,97,56,114,117,57,78,118,101,78,32,45,45,62)
savebuffer_size += 1
save_cache()
return chunks
end
local function save_game()
SaveNotCreatable = SaveNotCreatable
or IsolateLocalPlayer
or IsolatePlayers
or (NilInstances and global_container.getnilinstances) and true
or false
SaveNotCreatableWillBeEnabled = SaveNotCreatable
if IsolateLocalPlayer or IsolateLocalPlayerCharacter then
local LocalPlayer = service.Players.LocalPlayer
if LocalPlayer then
if IsolateLocalPlayer then
register_extra(string.char(76,111,99,97,108,80,108,97,121,101,114), LocalPlayer, true)
end
if IsolateLocalPlayerCharacter then
local Character = LocalPlayer.Character
if Character then
register_extra(string.char(76,111,99,97,108,80,108,97,121,101,114,32,67,104,97,114,97,99,116,101,114), Character, true, string.char(77,111,100,101,108))
end
end
end
end
if IsolateStarterPlayer then
register_extra(string.char(83,116,97,114,116,101,114,80,108,97,121,101,114), service.StarterPlayer)
end
if IsolatePlayers then
register_extra(string.char(80,108,97,121,101,114,115), service.Players)
end
if NilInstances and global_container.getnilinstances then
local nil_instances, nil_instances_size = {}, 1
local NilInstancesFixes = OPTIONS.NilInstancesFixes
for _, instance in global_container.getnilinstances() do
if instance == game then
instance = nil
else
local ClassName = instance.ClassName
local Fix = InheritsFix(NilInstancesFixes, ClassName, instance)
if Fix then
instance = Fix(instance, InstancesOverrides)
end
local Class = ClassList[ClassName]
if Class then
if Class.Service then instance = nil
end
end
end
if instance then
nil_instances[nil_instances_size] = instance
nil_instances_size += 1
end
end
register_extra(string.char(78,105,108,32,73,110,115,116,97,110,99,101,115), nil_instances)
end
local ELAPSED_PLACEHOLDER = string.char(64,64,69,76,65,80,83,69,68) .. string.gsub(service.HttpService:GenerateGUID(false), string.char(45), "") .. string.char(64,64)
local ELAPSED_WIDTH = string.char(37,45) .. #ELAPSED_PLACEHOLDER .. string.char(115)
local function stampElapsed(chunks, seconds)
local repl = string.format(ELAPSED_WIDTH, string.format(string.char(37,46,54,102,32,115,101,99,111,110,100,115), seconds))
if #repl ~= #ELAPSED_PLACEHOLDER then
return
end
for i, chunk in chunks do
local at = string.find(chunk, ELAPSED_PLACEHOLDER, 1, true)
if at then
chunks[i] = string.sub(chunk, 1, at - 1) .. repl .. string.sub(chunk, at + #ELAPSED_PLACEHOLDER)
return
end
end
end
local readmeExtra
if OPTIONS.ReadMe then
local binaryNote = ""
if not OPTIONS.Binary then
binaryNote = table.concat({string.char(10,9,9,73,102,32,121,111,117,32,100,105,100,110,39,116,32,115,97,118,101,32,105,110,32,66,105,110,97,114,121,32,40,114,98,120,108,41,32,45,32,105,116,39,115,32,114,101,99,111,109,109,101,110,100,101,100,32,116,111,32,115,97,118,101,32,116,104,101,32,103,97,109,101,32,114,105,103,104,116),string.char(32,97,119,97,121,32,116,111,32,116,97,107,101,32,97,100,118,97,110,116,97,103,101,32,111,102,32,116,104,101,32,98,105,110,97,114,121,32,102,111,114,109,97,116,32,38,32,116,111,32,112,114,101,115,101,114,118,101,32,118,97,108,117,101,115,32,111,102,32,99,101,114,116,97,105,110,32,112,114,111),string.char(112,101,114,116,105,101,115,32,105,102,32,121,111,117,32,117,115,101,100,32,73,103,110,111,114,101,68,101,102,97,117,108,116,80,114,111,112,101,114,116,105,101,115,32,115,101,116,116,105,110,103,32,40,97,115,32,116,104,101,121,32,109,105,103,104,116,32,99,104,97,110,103,101,32,105,110,32,116,104,101),string.char(32,102,117,116,117,114,101,41,46,10,9,9,89,111,117,32,99,97,110,32,100,111,32,116,104,97,116,32,98,121,32,103,111,105,110,103,32,116,111,32,70,73,76,69,32,45,62,32,83,97,118,101,32,116,111,32,70,105,108,101,32,65,115,32,45,62,32,77,97,107,101,32,115,117,114,101,32,70,105,108),string.char(101,32,78,97,109,101,32,101,110,100,115,32,119,105,116,104,32,46,114,98,120,108,32,45,62,32,83,97,118,101,10,10)})
end
local 			helpText = table.concat({string.char(10,9,9,83,101,114,118,101,114,83,116,111,114,97,103,101,44,32,83,101,114,118,101,114,83,99,114,105,112,116,83,101,114,118,105,99,101,32,97,110,100,32,83,101,114,118,101,114,32,83,99,114,105,112,116,115,32,97,114,101,32,73,77,80,79,83,83,73,66,76,69,32,116,111,32,115,97,118,101,32),string.char(98,101,99,97,117,115,101,32,111,102,32,70,105,108,116,101,114,105,110,103,69,110,97,98,108,101,100,46,10,10,9,9,73,102,32,121,111,117,114,32,112,108,97,121,101,114,32,99,97,110,110,111,116,32,115,112,97,119,110,32,105,110,116,111,32,116,104,101,32,103,97,109,101,44,32,112,108,101,97,115),string.char(101,32,109,111,118,101,32,116,104,101,32,115,99,114,105,112,116,115,32,105,110,32,83,116,97,114,116,101,114,80,108,97,121,101,114,32,115,111,109,101,119,104,101,114,101,32,101,108,115,101,32,111,114,32,100,101,108,101,116,101,32,116,104,101,109,46,32,84,104,101,110,32,114,117,110,32,96,103,97,109),string.char(101,58,71,101,116,83,101,114,118,105,99,101,40,34,80,108,97,121,101,114,115,34,41,46,67,104,97,114,97,99,116,101,114,65,117,116,111,76,111,97,100,115,32,61,32,116,114,117,101,96,46,10,9,9,65,110,100,32,117,115,101,32,34,80,108,97,121,32,72,101,114,101,34,32,116,111,32,115,116,97),string.char(114,116,32,103,97,109,101,32,105,110,115,116,101,97,100,32,111,102,32,34,80,108,97,121,34,32,116,111,32,115,112,97,119,110,32,121,111,117,114,32,67,104,97,114,97,99,116,101,114,32,119,104,101,114,101,32,121,111,117,114,32,67,97,109,101,114,97,32,99,117,114,114,101,110,116,108,121,32,105,115),string.char(46,10,10,9,9,73,102,32,116,104,101,32,99,104,97,116,32,115,121,115,116,101,109,32,100,111,101,115,32,110,111,116,32,119,111,114,107,44,32,112,108,101,97,115,101,32,117,115,101,32,116,104,101,32,101,120,112,108,111,114,101,114,32,97,110,100,32,100,101,108,101,116,101,32,101,118,101,114,121,116),string.char(104,105,110,103,32,105,110,115,105,100,101,32,116,104,101,32,84,101,120,116,67,104,97,116,83,101,114,118,105,99,101,47,67,104,97,116,32,115,101,114,118,105,99,101,40,115,41,46,10,9,9,79,114,32,114,117,110,32,96,103,97,109,101,58,71,101,116,83,101,114,118,105,99,101,40,34,67,104,97,116),string.char(34,41,58,67,108,101,97,114,65,108,108,67,104,105,108,100,114,101,110,40,41,32,103,97,109,101,58,71,101,116,83,101,114,118,105,99,101,40,34,84,101,120,116,67,104,97,116,83,101,114,118,105,99,101,34,41,58,67,108,101,97,114,65,108,108,67,104,105,108,100,114,101,110,40,41,96,10,10,9,9),string.char(73,102,32,85,110,105,111,110,32,97,110,100,32,77,101,115,104,80,97,114,116,32,99,111,108,108,105,115,105,111,110,115,32,100,111,110,39,116,32,119,111,114,107,44,32,114,117,110,32,116,104,101,32,115,99,114,105,112,116,32,98,101,108,111,119,32,105,110,32,116,104,101,32,83,116,117,100,105,111,32),string.char(67,111,109,109,97,110,100,32,66,97,114,58,10,10,9,9,108,111,99,97,108,32,67,32,61,32,103,97,109,101,58,71,101,116,83,101,114,118,105,99,101,40,34,67,111,114,101,71,117,105,34,41,10,9,9,108,111,99,97,108,32,68,32,61,32,69,110,117,109,46,67,111,108,108,105,115,105,111,110,70),string.char(105,100,101,108,105,116,121,46,68,101,102,97,117,108,116,10,9,9,102,111,114,32,95,44,32,118,32,105,110,32,103,97,109,101,58,71,101,116,68,101,115,99,101,110,100,97,110,116,115,40,41,32,100,111,10,9,9,9,105,102,32,118,58,73,115,65,40,34,84,114,105,97,110,103,108,101,77,101,115,104),string.char(80,97,114,116,34,41,32,97,110,100,32,110,111,116,32,118,58,73,115,68,101,115,99,101,110,100,97,110,116,79,102,40,67,41,32,116,104,101,110,10,9,9,9,9,118,46,67,111,108,108,105,115,105,111,110,70,105,100,101,108,105,116,121,32,61,32,68,10,9,9,9,101,110,100,10,9,9,101,110,100),string.char(10,9,9,112,114,105,110,116,40,34,68,111,110,101,34,41,10,10,9,9,73,102,32,121,111,117,32,99,97,110,39,116,32,109,111,118,101,32,116,104,101,32,67,97,109,101,114,97,44,32,114,117,110,32,116,104,105,115,32,115,99,114,105,112,116,32,105,110,32,116,104,101,32,83,116,117,100,105,111,32),string.char(67,111,109,109,97,110,100,32,66,97,114,58,10,10,9,9,119,111,114,107,115,112,97,99,101,46,67,117,114,114,101,110,116,67,97,109,101,114,97,46,67,97,109,101,114,97,84,121,112,101,32,61,32,69,110,117,109,46,67,97,109,101,114,97,84,121,112,101,46,70,105,120,101,100,10,10,9,9,79,114),string.char(32,68,101,115,116,114,111,121,32,116,104,101,32,67,97,109,101,114,97,46,10,10,9,9)})
local platformName = select(
2,
pcall(function()
return service.UserInputService:GetPlatform().Name end)
) or string.char(85,110,107,110,111,119,110)
local executorName = identify_executor and table.concat({ identify_executor() }, string.char(32)) or string.char(85,110,107,110,111,119,110)
local metaFooter = table.concat({
string.char(92,110,92,110,92,116,92,116,69,108,97,112,115,101,100,32,116,105,109,101,58,32),
ELAPSED_PLACEHOLDER,
string.char(92,110,92,116,92,116,68,97,116,101,32,40,85,84,67,41,58,32),
DateTime.now():FormatUniversalTime(string.char(76,76,32,76,84,83), string.char(101,110,45,103,98)),
string.char(32,80,108,97,99,101,73,100,58,32),
game.PlaceId,
string.char(32,80,108,97,99,101,86,101,114,115,105,111,110,58,32),
game.PlaceVersion,
string.char(32,67,108,105,101,110,116,32,86,101,114,115,105,111,110,58,32),
FULL_VERSION,
string.char(32,80,108,97,116,102,111,114,109,58,32),
platformName,
string.char(32,69,120,101,99,117,116,111,114,58,32),
executorName,
})
readmeExtra = register_extra(string.char(67,79,80,89,77,65,80,95,72,85,66), nil, nil, string.char(83,99,114,105,112,116), function()
local recoveredNote = ""
if #RecoveredScripts ~= 0 then
recoveredNote = string.char(92,116,92,116,73,77,80,79,82,84,65,78,84,58,32,79,114,105,103,105,110,97,108,32,83,111,117,114,99,101,32,111,102,32,116,104,101,115,101,32,83,99,114,105,112,116,115,32,119,97,115,32,82,101,99,111,118,101,114,101,100,58,32)
.. service.HttpService:JSONEncode(RecoveredScripts)
.. string.char(92,110)
end
local failedTypes = {}
for datatype, state in GHPPersisted do
if state ~= string.char(111,107) then
table.insert(failedTypes, datatype)
end
end
table.sort(failedTypes)
local ghpFailureHeader = ""
if #failedTypes > 0 then
ghpFailureHeader = table.concat({string.char(10,9,9,33,33,32,71,69,84,72,73,68,68,69,78,80,82,79,80,69,82,84,89,32,70,65,73,76,69,68,32,79,78,32,83,79,77,69,32,84,89,80,69,83,32,33,33,10,9,9,89,111,117,114,32,101,120,101,99,117,116,111,114,39,115,32,103,101,116,104,105,100,100,101,110,112,114,111,112,101),string.char(114,116,121,32,99,111,117,108,100,110,39,116,32,114,101,97,100,32,116,104,101,32,112,114,111,112,101,114,116,105,101,115,32,98,101,108,111,119,44,32,115,111,32,116,104,105,115,32,115,97,118,101,32,109,105,103,104,116,32,98,101,32,109,105,115,115,105,110,103,32,100,97,116,97,32,111,114,32,104,97),string.char(118,101,32,119,114,111,110,103,32,118,97,108,117,101,115,46,10,9,9,80,108,101,97,115,101,32,116,101,108,108,32,121,111,117,114,32,101,120,101,99,117,116,111,114,39,115,32,100,101,118,101,108,111,112,101,114,115,32,97,98,111,117,116,32,116,104,105,115,46,32,65,102,102,101,99,116,101,100,32,116),string.char(121,112,101,115,58,10,9,9)}) .. service.HttpService:JSONEncode(failedTypes) .. string.char(92,110,92,110)
end
return table.concat({
string.char(45,45,91,91,92,110),
string.char(92,116,92,116,84,104,97,110,107,32,121,111,117,32,102,111,114,32,117,115,105,110,103,32,67,79,80,89,77,65,80,95,72,85,66,32,91,106,111,105,110,32,110,111,119,93,32,104,116,116,112,115,58,47,47,100,105,115,99,111,114,100,46,103,103,47,97,56,114,117,57,78,118,101,78,46,92,110,92,110),
recoveredNote,
ghpFailureHeader,
binaryNote,
helpText,
metaFooter,
string.char(92,110,93,93),
})
end)
end
local allRoots = table.clone(ToSaveList)
for _, extra in pendingExtras do
for _, root in extra.roots do
allRoots[#allRoots + 1] = root
end
end
local ctx = collect(allRoots)
for _, extra in pendingExtras do
local src = extra.roots
local kept = table.create(#src)
for _, root in src do
if ctx.entries[root] then
kept[#kept + 1] = root
end
end
extra.collectedRoots = kept
end
if readmeExtra then
local readmeEntry = ctx.entries[readmeExtra.roots[1]]
if readmeEntry then
readmeEntry.deferLast = true end
end
local claimed = {}
for _, extra in pendingExtras do
for _, root in extra.collectedRoots do
claimed[root] = true
local rootEntry = ctx.entries[root]
local isVirtual = rootEntry and rootEntry.virtual
local toDetach = isVirtual and table.clone(rootEntry.children) or { root }
for _, node in toDetach do
local e = ctx.entries[node]
local old = e.parent and ctx.entries[e.parent]
if e.parent ~= root then
if old then
local kids = old.children
for i = #kids, 1, -1 do
if kids[i] == node then
table.remove(kids, i)
break
end
end
end
e.parent = isVirtual and root or nil
end
end
end
end
local mainRoots = table.create(#ctx.roots)
for _, root in ctx.roots do
if not claimed[root] then
mainRoots[#mainRoots + 1] = root
end
end
ctx.mainRoots = mainRoots
local chunks = OPTIONS.Binary and emitBinary(ctx) or emitXML(ctx)
if OPTIONS.ReadMe then
stampElapsed(chunks, os.clock() - elapse_t)
end
if CopyToClipboard then
setrbxclipboard(table.concat(chunks))
elseif Callback then
Callback(table.concat(chunks), chunks)
elseif OPTIONS.AlternativeWritefile and appendfile then
local SEGMENT_SIZE = 4145728
local batch, batchSize, written = {}, 0, 0
local function flush()
if batchSize == 0 then
return
end
written += batchSize
run_with_loading(
string.char(87,114,105,116,105,110,103,32,116,111,32,70,105,108,101,32) .. math.round(written / totalsize * 100) .. string.char(37),
nil,
true,
appendfile,
placename,
table.concat(batch)
)
table.clear(batch)
batchSize = 0
task.wait()
end
writefile(placename, "")
for _, chunk in chunks do
if #chunk >= SEGMENT_SIZE then
flush()
local offset = 1
while offset <= #chunk do
appendfile(placename, string.sub(chunk, offset, offset + SEGMENT_SIZE - 1))
offset += SEGMENT_SIZE
task.wait()
end
written += #chunk
else
batch[#batch + 1] = chunk
batchSize += #chunk
if batchSize >= SEGMENT_SIZE then
flush()
end
end
end
flush()
elseif writefile then
run_with_loading(
string.char(87,114,105,116,105,110,103,32) .. get_size_format() .. string.char(32,116,111,32,70,105,108,101),
nil,
true,
writefile,
placename,
table.concat(chunks)
)
end
end
local Connections = {}
local function Connect(event, func)
table.insert(Connections, event:Connect(func))
end
local function Cleanup()
for _, connection in Connections do
connection:Disconnect()
end
GLOBAL_ENV[placename] = nil
end
do
local Players = service.Players
if IgnoreList.Model ~= true then
local function ignoreCharacter(player)
Connect(player.CharacterAdded, function(character)
IgnoreList[character] = true
end)
local Character = player.Character
if Character then
IgnoreList[Character] = true
end
end
if not OPTIONS.SavePlayerCharacters then
Connect(Players.PlayerAdded, function(player)
ignoreCharacter(player)
end)
for _, player in Players:GetPlayers() do
ignoreCharacter(player)
end
else
IgnoreNotArchivable = false
end
end
end
if OPTIONS.KillAllScripts and not GLOBAL_ENV.USSI_KAS then
GLOBAL_ENV.USSI_KAS = true
game:GetService(string.char(83,99,114,105,112,116,67,111,110,116,101,120,116)):SetTimeout(math.clamp(SaveCacheInterval * 0.000047, 20, 30))
local self = coroutine.running()
do
local islclosure = islclosure
local isexecutorclosure = isexecutorclosure or checkclosure or isourclosure
local hookfunction = EXECUTOR_NAME ~= string.char(86,111,108,116) and hookfunction
local done = {}
local function filterNkill(f)
if not f then
return
end
for _, v in table.clone(f()) do
if not done[v] then
done[v] = true
local _type = type(v)
if _type == string.char(116,104,114,101,97,100) then
if v ~= self then
pcall(coroutine.close, v)
end
elseif _type == string.char(102,117,110,99,116,105,111,110) then
if
(not islclosure or islclosure(v))
and (not isexecutorclosure or not isexecutorclosure(v))
then
if hookfunction then
pcall(hookfunction, v, coroutine.yield)
end
end
end
end
end
end
filterNkill(debug and debug.getregistry or getreg or getregistry)
filterNkill(getallthreads)
filterNkill(getgc)
end
end
if IsolateStarterPlayer then
IgnoreList.StarterPlayer = false
end
if IsolatePlayers then
IgnoreList.Players = false
end
if OPTIONS.ShowStatus then
do
local Exists = GLOBAL_ENV.USSI_statustext
if Exists then
Exists:Destroy()
end
end
local StatusGui = Instance.new(string.char(83,99,114,101,101,110,71,117,105))
GLOBAL_ENV.USSI_statustext = StatusGui
StatusGui.DisplayOrder = 2e9
pcall(function() StatusGui.OnTopOfCoreBlur = true
end)
StatusText = Instance.new(string.char(84,101,120,116,76,97,98,101,108))
StatusText.Text = string.char(83,97,118,105,110,103,46,46,46)
StatusText.BackgroundTransparency = 1
StatusText.Font = Enum.Font.Code
StatusText.AnchorPoint = Vector2.new(1)
StatusText.Position = UDim2.new(1)
StatusText.Size = UDim2.new(0.3, 0, 0, 20)
StatusText.TextColor3 = Color3.new(1, 1, 1)
StatusText.TextScaled = true
StatusText.TextStrokeTransparency = 0.7
StatusText.TextXAlignment = Enum.TextXAlignment.Right
StatusText.TextYAlignment = Enum.TextYAlignment.Top
StatusText.Parent = StatusGui
local function randomString()
local length = math.random(10, 20)
local randomarray = table.create(length)
for i = 1, length do
randomarray[i] = string.char(math.random(32, 126))
end
return table.concat(randomarray)
end
if global_container.gethui then
StatusGui.Name = randomString()
StatusGui.Parent = global_container.gethui()
else
if global_container.protectgui then
StatusGui.Name = randomString()
global_container.protectgui(StatusGui)
StatusGui.Parent = game:GetService(string.char(67,111,114,101,71,117,105))
else
local RobloxGui = game:GetService(string.char(67,111,114,101,71,117,105)):FindFirstChild(string.char(82,111,98,108,111,120,71,117,105))
if RobloxGui then
StatusGui.Parent = RobloxGui
else
StatusGui.Name = randomString()
StatusGui.Parent = game:GetService(string.char(67,111,114,101,71,117,105))
end
end
end
end
local kickSnapshot = GLOBAL_ENV.USSI_kicksnapshot
if not kickSnapshot then
kickSnapshot = {}
GLOBAL_ENV.USSI_kicksnapshot = kickSnapshot
end
local function snapshotKick(LocalPlayer)
local cached = kickSnapshot[LocalPlayer]
if not cached then
cached = { [LocalPlayer] = LocalPlayer:GetChildren() }
local ps = LocalPlayer:FindFirstChildOfClass(string.char(80,108,97,121,101,114,83,99,114,105,112,116,115))
local function walk(inst)
local kids = inst:GetChildren()
cached[inst] = kids
for _, child in kids do
walk(child)
end
end
if ps then
walk(ps)
end
kickSnapshot[LocalPlayer] = cached
end
for inst, kids in cached do
InstancesOverrides[inst] = { __Children = kids }
end
end
if OPTIONS.SafeMode then
task.spawn(function()
local LocalPlayer = GetLocalPlayer()
snapshotKick(LocalPlayer)
local msg =
table.concat({string.char(91,83,65,86,69,73,78,83,84,65,78,67,69,32,83,65,70,69,77,79,68,69,93,92,110,83,97,118,105,110,103,46,46,92,110,68,111,32,78,79,84,32,108,101,97,118,101,92,110,76,86,76,55,32,69,120,101,99,117,116,111,114,32,82,69,67,79,77,77,69,78,68,69,68,32,102,111,114,32,109),string.char(111,114,101,32,83,65,70,69,84,89,92,110,84,111,32,68,105,115,97,98,108,101,32,116,104,105,115,58,32,83,97,102,101,77,111,100,101,61,102,97,108,115,101,32,40,76,101,115,115,32,80,114,111,116,101,99,116,105,111,110,41)})
local function Kick()
LocalPlayer:Kick(msg)
end
Kick()
pcall(function()
Connect(service.GuiService.ErrorMessageChanged, function()
if service.GuiService:GetErrorMessage() ~= msg then
Kick()
end
end)
end)
wait_for_render()
end)
if CustomOptions_valid[string.char(66,111,111,115,116,70,80,83)] == nil then
OPTIONS.BoostFPS = true
end
end
local function childrenOf(instance)
local override = InstancesOverrides[instance]
return override and override.__Children or instance:GetChildren()
end
if OPTIONS.IgnoreDefaultPlayerScripts then
local default_scripts = arrayToDict({
ModuleScript = { string.char(80,108,97,121,101,114,77,111,100,117,108,101) },
LocalScript = {
string.char(66,117,98,98,108,101,67,104,97,116),
string.char(67,104,97,116,83,99,114,105,112,116),
string.char(80,108,97,121,101,114,83,99,114,105,112,116,115,76,111,97,100,101,114),
string.char(82,98,120,67,104,97,114,97,99,116,101,114,83,111,117,110,100,115),
},
}, true)
local function ignorePath(path)
if path then
for _, child in childrenOf(path) do
local class_match = default_scripts[child.ClassName]
if class_match and class_match[child.Name] then
DecompileIgnore[child] = true
end
ignorePath(child)
end
end
end
ignorePath(service.StarterPlayer)
local LocalPlayer = service.Players.LocalPlayer
if LocalPlayer then
for _, child in childrenOf(LocalPlayer) do
if child:IsA(string.char(80,108,97,121,101,114,83,99,114,105,112,116,115)) then
ignorePath(child)
break
end
end
end
end
if OPTIONS.BoostFPS then
pcall(function()
service.RunService:Set3dRenderingEnabled(false)
end)
end
if OPTIONS.AntiIdle then
local Idled = GetLocalPlayer().Idled
Connect(Idled, function()
service.VirtualInputManager:SendMouseWheelEvent(
service.UserInputService:GetMouseLocation().X,
service.UserInputService:GetMouseLocation().Y,
true,
game
)
end)
end
if not ClassList then do if not RiskyServicesDisabled.UGC then
local UGCValidationService gethiddenproperty_fallback = function(instance, propertyName)
if not UGCValidationService then
UGCValidationService = service.UGCValidationService
end
return UGCValidationService:GetPropertyValue(instance, propertyName) end
end
if gethiddenproperty then
local o, r = pcall(gethiddenproperty, workspace, string.char(83,116,114,101,97,109,79,117,116,66,101,104,97,118,105,111,114))
if not o or r ~= nil and typeof(r) ~= string.char(69,110,117,109,73,116,101,109) then gethiddenproperty = nil
else
o, r = pcall(gethiddenproperty, Instance.new(string.char(65,110,105,109,97,116,105,111,110,82,105,103,68,97,116,97), Instance.new(string.char(70,111,108,100,101,114))), string.char(112,97,114,101,110,116)) if o and r ~= nil and type(r) ~= string.char(115,116,114,105,110,103) then
gethiddenproperty = nil
end
end
end
do
if
not bit32.byteswap
or not (function()
local o, r = pcall(bit32.byteswap, 2712847316)
if not o then
return end
return r == 3569595041
end)()
then local b32 = table.clone(bit32)
b32.byteswap = function(n)
return bit32.bor(
bit32.lshift(n, 24),
bit32.band(bit32.lshift(n, 8), 0xFF0000),
bit32.band(bit32.rshift(n, 8), 0xFF00),
bit32.rshift(n, 24)
)
end
if table.isfrozen(bit32) then
b32 = table.freeze(b32)
end
GLOBAL_ENV.bit32 = b32
end
end
local function benchmark(funcs, iters, ...)
local ranking = table.create(3)
for i, f in funcs do
local start = os.clock()
for _ = 1, iters do
f(...)
end
ranking[i] = { t = os.clock() - start, f = f }
end
table.sort(ranking, function(a, b)
return a.t < b.t
end)
return ranking[1].f
end
local function pickFastestBy(label, candidates, works, iters, benchInput, ...)
local valid = {}
for _, f in candidates do
if f then
local ok, good = pcall(works, f)
if ok and good then
valid[#valid + 1] = f
end
end
end
if #valid == 0 then
return nil
elseif #valid == 1 then
return valid[1]
end
return benchmark(valid, iters, benchInput, ...)
end
local rbxcrypt_encode, rbxcrypt_decode
pcall(function()
local rbxcrypt_b64 = loadstring(
game:HttpGet(
table.concat({string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,100,97,105,108,121,51,48,49,52,47,114,98,120,45,97,108,103,111,114,105,116,104,109,115,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,115,114,99,47,69),string.char(110,99,111,100,105,110,103,47,66,97,115,101,54,52,46,108,117,97,117)}),
true
),
string.char(66,97,115,101,54,52)
)()
local enc = rbxcrypt_b64.Encode
rbxcrypt_encode = function(raw)
return buffer.tostring(enc(buffer.fromstring(raw)))
end
local dec = rbxcrypt_b64.Decode
rbxcrypt_decode = function(raw)
return buffer.tostring(dec(buffer.fromstring(raw)))
end
end)
local es_encode, es_decode, es_zstdcompress
if not RiskyServicesDisabled.Encoding then
local EncodingService = game:GetService(string.char(69,110,99,111,100,105,110,103,83,101,114,118,105,99,101))
es_encode = function(raw)
return buffer.tostring(EncodingService:Base64Encode(buffer.fromstring(raw)))
end
es_decode = function(raw)
return buffer.tostring(EncodingService:Base64Decode(buffer.fromstring(raw)))
end
local ZSTD_ALGO_ENUM = Enum.CompressionAlgorithm.Zstd
es_zstdcompress = function(raw, level)
return buffer.tostring(
EncodingService:CompressBuffer(buffer.fromstring(raw), ZSTD_ALGO_ENUM, level)
)
end
end
local BASE64_TEST = string.rep(string.char(92,49,92,48,92,48,92,48,92,49,92,50,92,51,92,52,92,53,92,54,92,55), 50)
local function b64EncWorks(f)
return f(string.char(92,49,92,48,92,48,92,48,92,49)) == string.char(65,81,65,65,65,65,69,61)
end
base64encode = pickFastestBy(
string.char(98,97,115,101,54,52,101,110,99,111,100,101),
{ base64encode, rbxcrypt_encode, es_encode },
b64EncWorks,
50,
BASE64_TEST
)
if not base64encode then
warn(string.char(98,97,115,101,54,52,101,110,99,111,100,101,32,110,111,116,32,102,111,117,110,100))
Cleanup()
return
end
local function b64DecWorks(f)
return f(string.char(65,81,65,65,65,65,69,61)) == string.char(92,49,92,48,92,48,92,48,92,49)
end
base64decode = pickFastestBy(
string.char(98,97,115,101,54,52,100,101,99,111,100,101),
{ base64decode, rbxcrypt_decode, es_decode },
b64DecWorks,
50,
base64encode(BASE64_TEST)
)
local HttpService = service.HttpService
local function http_zstdcompress(input)
local ok, encoded = pcall(HttpService.JSONEncode, HttpService, buffer.fromstring(input)) if not ok then
return nil
end
local keyStart = string_find(encoded, string.char(34,122,98,97,115,101,54,52,34))
if not keyStart then
return nil
end
local valueStart = string_find(encoded, string.char(34), keyStart + 9)
if not valueStart then
return nil
end
local valueEnd = string_find(encoded, string.char(34), valueStart + 1)
if not valueEnd then
return nil
end
local b64 = string.sub(encoded, valueStart + 1, valueEnd - 1)
return base64decode(b64)
end
local COMPRESS_TEST
do
local n = 4000
local planes = table.create(4)
for p = 1, 4 do
local bytes = table.create(n)
for i = 1, n do
bytes[i] = p <= 2 and (i % 3) or ((i * 2654435761) % 256)
end
planes[p] = string.char(table.unpack(bytes, 1, math.min(n, 7997)))
end
COMPRESS_TEST = table.concat(planes)
end
local function zstdWorks(f)
local out = f(COMPRESS_TEST)
return type(out) == string.char(115,116,114,105,110,103) and #out > 4 and string.sub(out, 1, 4) == string.char(92,52,48,92,49,56,49,92,52,55,92,50,53,51)
end
zstdcompress = pickFastestBy(
string.char(122,115,116,100,99,111,109,112,114,101,115,115),
{ zstdcompress, http_zstdcompress, es_zstdcompress },
zstdWorks,
10,
COMPRESS_TEST
)
local llz4_compress
pcall(function()
local llz4 = loadstring(
game:HttpGet(string.char(104,116,116,112,115,58,47,47,114,97,119,46,103,105,116,104,117,98,117,115,101,114,99,111,110,116,101,110,116,46,99,111,109,47,82,105,115,107,111,90,83,47,108,108,122,52,47,114,101,102,115,47,104,101,97,100,115,47,109,97,105,110,47,108,108,122,52,46,108,117,97,117), true),
string.char(108,108,122,52)
)()
llz4_compress = llz4.compress
end)
local LZ4_PROBE = string.char(92,49,92,50,92,51,92,52,92,53,92,54,92,55,92,56)
local function lz4Works(f)
local out = f(LZ4_PROBE)
return type(out) == string.char(115,116,114,105,110,103)
and #out == #LZ4_PROBE + 1
and string.byte(out, 1) == #LZ4_PROBE * 16
and string.sub(out, 2) == LZ4_PROBE
end
lz4compress = pickFastestBy(string.char(108,122,52,99,111,109,112,114,101,115,115), { lz4compress, llz4_compress }, lz4Works, 10, COMPRESS_TEST)
end
do
local ok, result = pcall(FetchAPI)
if ok then
ClassList = result
else
warn(string.char(70,97,105,108,101,100,32,116,111,32,108,111,97,100,32,116,104,101,32,65,80,73,32,68,117,109,112))
warn(result)
Cleanup()
return
end
end
end
elapse_t = os.clock()
local ok, err = xpcall(save_game, function(err)
return debug.traceback(err)
end)
if OPTIONS.BoostFPS then
pcall(function()
local max = 5
task.delay(
math.clamp(max - (os.clock() - elapse_t), 0, max),
service.GuiService.ClearError,
service.GuiService
)
service.RunService:Set3dRenderingEnabled(true)
end)
end
if old_gethiddenproperty then
gethiddenproperty = old_gethiddenproperty
end
Cleanup()
elapse_t = os.clock() - elapse_t
local Log10 = math.log10(elapse_t)
local ExtraTime = 10
if StatusText then
task.spawn(function()
if ok then
StatusText.Text = string.format(string.char(83,97,118,101,100,33,32,84,105,109,101,32,37,46,51,102,32,115,101,99,111,110,100,115,59,32,83,105,122,101,32,37,115), elapse_t, get_size_format())
StatusText.TextColor3 = Color3.new(0, 1)
task.wait(Log10 * 2 + ExtraTime)
else
if LoadingThread then
task.cancel(LoadingThread)
LoadingThread = nil
end
StatusText.Text = string.char(70,97,105,108,101,100,33,32,67,104,101,99,107,32,70,57,32,99,111,110,115,111,108,101,32,102,111,114,32,109,111,114,101,32,105,110,102,111)
StatusText.TextColor3 = Color3.new(1)
warn(string.char(69,114,114,111,114,32,102,111,117,110,100,32,119,104,105,108,101,32,115,97,118,105,110,103,58))
warn(err)
task.wait(Log10 + ExtraTime)
end
StatusText:Destroy()
end)
end
if OPTIONS.ShutdownWhenDone and ok then
task.wait(Log10 * 2 + ExtraTime)
game:Shutdown()
end
end
_G.saveinstance = synsaveinstance
