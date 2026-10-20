local P=dofile('PairProtocol.lua')
local C=dofile('PairController.lua')
local n=0
local function eq(a,b) n=n+1; assert(a==b,tostring(a)..' ~= '..tostring(b)) end
local players={}
local main={Name='MainUser',Parent=players}
local alt={Name='AltUser',Parent=players}
function players:GetPlayers() return {main,alt} end
for q=1,3 do eq(P.questAt(q*10000),q); eq(P.questAt(q*10000+12),q) end
eq(P.questAt(10013),nil); eq(P.questAt(nil),nil); eq(P.questAt(0/0),nil)
eq(P.player(players,' @ALTuser ',main),alt); eq(P.player(players,'MainUser',main),nil)
eq(P.player(players,'Display Name',main),nil)
local t=0
local char={};local position={Y=0}
local vecmt={__sub=function() return {Magnitude=0} end}
setmetatable(position,vecmt)
local root={Position=position,CFrame='return'}
local tycoon={Name='ÅTycoonMainUser'}
function tycoon:IsA(c) return c=='Model' end
function tycoon:IsDescendantOf() return self.present end
tycoon.present=true
local world={GetChildren=function() return {tycoon} end}
eq(P.tycoon(world,'MainUser'),tycoon);eq(P.tycoon(world,'Other'),nil)
world.GetChildren=function() return {tycoon,tycoon} end
eq(P.tycoon(world,'MainUser'),nil)
workspace={}
CFrame={new=function(v) return v end}
local part={Position=position,IsDescendantOf=function() return true end}
local a={g='Tycoon',inArena=true,e=0,rockState=false}
function a:body(p) if self.dead then return nil end; return char,root,{} end
function a:glove() return self.g end
function a:release() self.released=true end
function a:serviceInput() end
function a:arena() return self.inArena end
function a:portal() return {CFrame='portal'} end
function a:teleport(cf) self.lastTP=cf end
function a:pressE() self.e=self.e+1 end
function a:platform(q) self.platformQuest=q; position.Y=q*10000 end
function a:destruct() return self.hasTycoon and part end
function a:equipDiamond() self.g='Diamond' end
function a:rock() return self.rockState end
function a:Destroy() self.destroyed=true end
local original=P.tycoon
P.tycoon=function() return a.hasTycoon and tycoon end
local s=C.new(a,P,players,main,function() return t end)
eq(s:start(),false);eq(s:connect('AltUser'),true);eq(s:start(),false)
s.Quest1=true;eq(s:start(),true)
s:step();eq(a.e,1);eq(s.State,'spawn2')
t=.9;s:step();eq(a.e,1)
t=1;s:step();eq(a.e,2);eq(s.State,'waitTycoon')
a.hasTycoon=true;s:step();eq(s.State,'hold');eq(a.platformQuest,1)
s:stop();eq(a.lastTP,'return');eq(s.Running,false)
-- Alt waits for a stable height signal, then confirms both rock and position.
a.g='Diamond';s=C.new(a,P,players,alt,function() return t end);s.Role='Alt'
eq(s:connect('MainUser'),true);eq(s:start(),true);s:step();eq(s.State,'waitSignal')
s:step();t=t+2;s:step();eq(s.State,'positionAlt')
s:step();eq(s.State,'rockAlt');t=t+1;s:step();eq(s.State,'verifyRock')
a.rockState=true;s:step();eq(s.State,'hold');s:step();eq(s.Running,true)
position.Y=0;s:step();eq(s.Running,false);eq(a.rockState,true)
-- Unknown transformation never causes a blind second E.
position.Y=10000;a.rockState=nil
s:connect('MainUser');eq(s:start(),true);s:step();s:step();t=t+2;s:step();s:step();t=t+1;s:step()
eq(s.State,'verifyRock');local attempts=a.e;t=t+17;s:step();eq(s.Running,false);eq(a.e,attempts)
-- Explicit false retries; death and leaving the server stop immediately.
a.rockState=false;s:connect('MainUser');s:start();s:step();s:step();t=t+2;s:step();s:step();t=t+1;s:step();t=t+17;s:step();eq(s.State,'rockAlt')
a.dead=true;s:step();eq(s.Running,false);a.dead=false
s:connect('MainUser');s:start();main.Parent=nil;s:step();eq(s.Running,false);main.Parent=players
-- Unsupported quests never run Quest 1 accidentally.
position.Y=20000;s:connect('MainUser');s:start();s:step();s:step();t=t+2;s:step();eq(s.Running,false)
s:Destroy();eq(a.destroyed,true);eq(s.Destroyed,true)
P.tycoon=original
print('PASS: '..n..' pairing, ownership, state, input timing and cancellation assertions')
