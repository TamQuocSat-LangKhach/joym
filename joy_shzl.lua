local extension = Package("joy_shzl")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_shzl"] = "欢乐-神话再临",
}

local U = require "packages/utility/utility"

-- 风

local xiaoqiao = General(extension, "joyex__xiaoqiao", "wu", 3, 3, General.Female)
local joyex__tianxiang = fk.CreateTriggerSkill{
  name = "joyex__tianxiang",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player
  end,
  on_cost = function(self, event, target, player, data)
    local tar, card =  player.room:askForChooseCardAndPlayers(player, table.map(player.room:getOtherPlayers(player), function (p)
      return p.id end), 1, 1, ".|.|heart|hand", "#joyex__tianxiang-choose", self.name, true)
    if #tar > 0 and card then
      self.cost_data = {tar[1], card}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard(self.cost_data[2], self.name, player, player)
    local damage = table.simpleClone(data)
    damage.to = to
    room:damage(damage)
    if not to.dead then
      local n = 1
      if not player.dead then
        local choice = room:askForChoice(player, {"1", tostring(math.min(to:getLostHp(), 5))}, self.name, "#joyex__tianxiang-choice::"..to.id)
        n = tonumber(choice)
      end
      to:drawCards(n, self.name)
    end
    return true
  end,
}
local joyex__hongyan = fk.CreateFilterSkill{
  name = "joyex__hongyan",
  frequency = Skill.Compulsory,
  card_filter = function(self, to_select, player)
    return to_select.suit == Card.Spade and player:hasSkill(self)
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}
local joyex__hongyan_maxcards = fk.CreateMaxCardsSkill{
  name = "#joyex__hongyan_maxcards",
  frequency = Skill.Compulsory,
  fixed_func = function(self, player)
    if player:hasSkill("joyex__hongyan") and table.find(player:getCardIds("e"), function(id)
      return Fk:getCardById(id).suit == Card.Heart or Fk:getCardById(id).suit == Card.Spade end) then  --FIXME: 耦！
      return player.maxHp
    end
  end
}
joyex__hongyan:addRelatedSkill(joyex__hongyan_maxcards)
xiaoqiao:addSkill(joyex__tianxiang)
xiaoqiao:addSkill(joyex__hongyan)
Fk:loadTranslationTable{
  ["joyex__xiaoqiao"] = "界小乔",
  ["joyex__tianxiang"] = "天香",
  [":joyex__tianxiang"] = "当你受到伤害时，你可以弃置一张<font color='red'>♥</font>手牌，将此伤害转移给一名其他角色，然后你选择一项："..
  "1.其摸一张牌；2.其摸X张牌（X为其已损失体力值且至多为5）。",
  ["joyex__hongyan"] = "红颜",
  [":joyex__hongyan"] = "锁定技，你的♠牌视为<font color='red'>♥</font>牌。若你的装备区有<font color='red'>♥</font>牌，你的手牌上限等于体力上限。",
  ["#joyex__tianxiang-choose" ] = "天香：弃置一张<font color='red'>♥</font>手牌将此伤害转移给一名其他角色，然后令其摸一张牌或X张牌（X为其已损失体力值）",
  ["#joyex__tianxiang-choice"] = "天香：选择令 %dest 摸牌数",
}

-- 火

local dianwei = General(extension, "joyex__dianwei", "wei", 4)
local joyex__qiangxi = fk.CreateActiveSkill{
  name = "joyex__qiangxi",
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player.hp > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    if #selected == 0 and Self:inMyAttackRange(Fk:currentRoom():getPlayerById(to_select)) then
      return not table.contains(U.getMark(Self, "joyex__qiangxi_targets-phase"), to_select)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = U.getMark(player, "joyex__qiangxi_targets-phase")
    table.insertIfNeed(mark, target.id)
    room:setPlayerMark(player, "joyex__qiangxi_targets-phase", mark)
    room:loseHp(player, 1, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
    end
    if not target.dead then
      room:damage{
        from = player,
        to = target,
        damage = 1,
        skillName = self.name,
      }
    end
  end,
}
local joyex__qiangxi_trigger = fk.CreateTriggerSkill{
  name = "#joyex__qiangxi_trigger",
  mute = true,
  main_skill = joyex__qiangxi,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(joyex__qiangxi) and target ~= player and not player:isNude()
  end,
  on_cost = function (self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, "joyex__qiangxi", true, ".|.|.|.|.|equip", "#joyex__qiangxi-cost:"..target.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, { target.id })
    room:throwCard(self.cost_data, "joyex__qiangxi", player, player)
    data.damage = data.damage + 1
  end,
}
joyex__qiangxi:addRelatedSkill(joyex__qiangxi_trigger)
dianwei:addSkill(joyex__qiangxi)

Fk:loadTranslationTable{
  ["joyex__dianwei"] = "界典韦",
  ["#joyex__dianwei"] = "古之恶来",
  ["joyex__qiangxi"] = "强袭",
  [":joyex__qiangxi"] = "出牌阶段每名角色限一次，你可以失去一点体力，并摸一张牌，然后对攻击范围内一名角色造成1点伤害；每当其他角色受到伤害时，你可以弃置一张装备牌，令此伤害+1。",
  ["#joyex__qiangxi_trigger"] = "强袭",
  ["#joyex__qiangxi-cost"] = "强袭：你可以弃置一张装备牌，令 %src 受到的伤害+1",
}

-- 林

local xuhuang = General(extension, "joyex__xuhuang", "wei", 4)
local joyex__duanliang = fk.CreateViewAsSkill{
  name = "joyex__duanliang",
  anim_type = "control",
  pattern = "supply_shortage",
  prompt = "#joyex__duanliang",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and Fk:getCardById(to_select).type ~= Card.TypeTrick
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("supply_shortage")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
local joyex__duanliang_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__duanliang_targetmod",
  main_skill = joyex__duanliang,
  bypass_distances =  function(self, player, skill, card, to)
    return player:hasSkill(self) and skill.name == "supply_shortage_skill" and to:getHandcardNum() >= player:getHandcardNum()
  end,
}
local joyex__jiezi = fk.CreateTriggerSkill{
  name = "joyex__jiezi",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseSkipping},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player and target.skipped_phases[Player.Draw] and  --FIXME: 此时机无data，需补充
      player:usedSkillTimes(self.name, Player.HistoryRound) < 2
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
joyex__duanliang:addRelatedSkill(joyex__duanliang_targetmod)
xuhuang:addSkill(joyex__duanliang)
xuhuang:addSkill(joyex__jiezi)
Fk:loadTranslationTable{
  ["joyex__xuhuang"] = "界徐晃",
  ["joyex__duanliang"] = "断粮",
  [":joyex__duanliang"] = "你可以将一张黑色基本牌或装备牌当【兵粮寸断】使用；你对手牌数不小于你的角色使用【兵粮寸断】无距离限制。",
  ["joyex__jiezi"] = "截辎",
  [":joyex__jiezi"] = "锁定技，每轮限两次，一名其他角色跳过摸牌阶段后，你摸两张牌。",
  ["#joyex__duanliang"] = "断粮：你可以将一张黑色基本牌或装备牌当【兵粮寸断】使用",
}



local caopi = General(extension, "joy__caopi", "wei", 3)
local xingshang = fk.CreateTriggerSkill{
  name = "joy__xingshang",
  anim_type = "drawcard",
  events = {fk.Death},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not target:isNude()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("fangzhu")
    local cards = target:getCardIds{Player.Hand, Player.Equip}
    if #cards > 0 then
      local dummy = Fk:cloneCard'slash'
      dummy:addSubcards(cards)
      room:obtainCard(player.id, dummy, false, fk.ReasonPrey)
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
local fangzhu = fk.CreateTriggerSkill{
  name = "joy__fangzhu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#joy__fangzhu-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("fangzhu")
    local to = player.room:getPlayerById(self.cost_data)
    to:turnOver()
    if not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
caopi:addSkill(xingshang)
caopi:addSkill(fangzhu)
caopi:addSkill("songwei")
Fk:loadTranslationTable{
  ["joy__caopi"] = "曹丕",
  ["joy__xingshang"] = "行殇",
  [":joy__xingshang"] = "当其他角色死亡时，你可以获得其所有牌并摸一张牌。",
  ["joy__fangzhu"] = "放逐",
  [":joy__fangzhu"] = "当你受到伤害后，你可以令一名其他角色翻面，然后该角色摸一张牌。",
  ["#joy__fangzhu-choose"] = "放逐：你可以令一名其他角色翻面，然后其摸一张牌",
}

-- thunder

local lukang = General(extension, "joy__lukang", "wu", 4)
lukang:addSkill("qianjie")
local jueyan = fk.CreateActiveSkill{
  name = "joy__jueyan",
  can_use = function (self, player)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 then
      local slots = player:getAvailableEquipSlots()
      return table.contains(slots, Player.WeaponSlot) or table.contains(slots, Player.ArmorSlot) or
      (table.contains(slots, Player.OffensiveRideSlot) and table.contains(slots, Player.DefensiveRideSlot))
    end
  end,
  card_filter = Util.FalseFunc,
  card_num = 0,
  target_num = 0,
  interaction = function()
    local slots = Self:getAvailableEquipSlots()
    local choices = {}
    if table.contains(slots, Player.WeaponSlot) then table.insert(choices, "WeaponSlot") end
    if table.contains(slots, Player.ArmorSlot) then table.insert(choices, "ArmorSlot") end
    if table.contains(slots, Player.OffensiveRideSlot) and table.contains(slots, Player.DefensiveRideSlot) then
      table.insert(choices, "RideSlot")
    end
    if #slots == 0 then return end
    return UI.ComboBox {choices = choices}
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local choice = self.interaction.data
    if choice == "RideSlot" then
      choice = {Player.OffensiveRideSlot, Player.DefensiveRideSlot}
    end
    room:abortPlayerArea(player, choice)
    if player.dead then return end
    if choice == 'WeaponSlot' then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn", 3)
    elseif choice == 'ArmorSlot' then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 3)
      player:drawCards(3, self.name)
    else
      room:addPlayerMark(player, "jueyan_distance-turn")
      if player:isWounded() then
        room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
      end
      if not player:hasSkill("ex__jizhi",true) then
        room:handleAddLoseSkills(player, "ex__jizhi", nil, false)
        room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
          room:handleAddLoseSkills(player, "-ex__jizhi", nil, false)
        end)
      end
    end
  end,
}
local jueyan_targetmod = fk.CreateTargetModSkill{
  name = "#joy__jueyan_targetmod",
  bypass_distances = function(self, player, skill, card, to)
    return player:getMark("jueyan_distance-turn") > 0
  end,
}
jueyan:addRelatedSkill(jueyan_targetmod)
lukang:addSkill(jueyan)
lukang:addRelatedSkill("ex__jizhi")
local huairou = fk.CreateActiveSkill{
  name = "joy__huairou",
  anim_type = "drawcard",
  can_use = function(self, player)
    return not player:isNude()
  end,
  card_num = 1,
  card_filter = function(self, to_select, selected)
    return #selected < 1 and Fk:getCardById(to_select).type == Card.TypeEquip
    and table.contains(Self.sealedSlots, Util.convertSubtypeAndEquipSlot(Fk:getCardById(to_select).sub_type))
  end,
  target_num = 0,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:moveCards({
      ids = effect.cards,
      from = player.id,
      toArea = Card.DiscardPile,
      skillName = self.name,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = player.id
    })
    if player.dead then return end
    local allCardMapper = {}
    local allCardNames = {}
    local mark = U.getMark(player, "joy__huairou-turn")
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(mark, card.name) and card.type ~= Card.TypeEquip and (room:getCardArea(id) == Card.DrawPile or room:getCardArea(id) == Card.DiscardPile) then
        if allCardMapper[card.name] == nil then
          allCardMapper[card.name] = {}
          table.insert(allCardNames, card.name)
        end
        table.insert(allCardMapper[card.name], id)
      end
    end
    if #allCardNames == 0 then return end
    local cardName = room:askForChoice(player, allCardNames, self.name)
    table.insert(mark, cardName)
    room:setPlayerMark(player, "joy__huairou-turn", mark)
    room:moveCardTo(table.random(allCardMapper[cardName]), Card.PlayerHand, player, fk.ReasonPrey, self.name)
  end,
}
lukang:addSkill(huairou)

Fk:loadTranslationTable{
  ["joy__lukang"] = "陆抗",
  ["#joy__lukang"] = "社稷之瑰宝",
  ["joy__jueyan"] = "决堰",
  [":joy__jueyan"] = "出牌阶段限一次，你可以废除你装备区里的一种装备栏，然后执行对应的一项：武器栏，你于此回合内可以多使用三张【杀】；防具栏，摸三张牌，本回合手牌上限+3；2个坐骑栏，回复1点体力，本回合获得技能〖集智〗，且你使用牌无距离限制。",
  ["RideSlot"] = "坐骑栏",
  ["joy__huairou"] = "怀柔",
  [":joy__huairou"] = "出牌阶段，你可以将一张已废除装备栏对应的装备牌置入弃牌堆，然后获得一张指定牌名的基本牌或锦囊牌（每牌名每回合限一次)",
}

-- shadow

local yanyan = General(extension, "joy__yanyan", "shu", 4)
local joy__juzhan = fk.CreateTriggerSkill{
  name = "joy__juzhan",
  mute = true,
  events = {fk.TargetSpecified, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and data.card.trueName == "slash") then return false end
    if event == fk.TargetConfirmed then
      return player.id ~= data.from and not player.room:getPlayerById(data.from).dead
    else
      return not player.room:getPlayerById(data.to):isNude()
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TargetConfirmed then
        room:notifySkillInvoked(player, self.name, "defensive")
        local from = room:getPlayerById(data.from)
        player:drawCards(1, self.name)
        if from.dead then return end
        from:drawCards(1, self.name)
        if from.dead then return end
        local mark = U.getMark(from, "@@joy__juzhan-turn")
        table.insertIfNeed(mark, player.id)
        room:setPlayerMark(from, "@@joy__juzhan-turn", mark)
    else
        room:notifySkillInvoked(player, self.name, "control")
        local to = room:getPlayerById(data.to)
        room:moveCardTo(room:askForCardChosen(player, to, "he", self.name), Card.PlayerHand, player, fk.ReasonPrey, self.name, "", false, player.id)
        local mark = U.getMark(player, "joy__juzhan_red-turn")
        table.insertIfNeed(mark, to.id)
        room:setPlayerMark(player, "joy__juzhan_red-turn", mark)
    end
  end,
}
local joy__juzhan_prohibit = fk.CreateProhibitSkill{
  name = "#joy__juzhan_prohibit",
  is_prohibited = function(self, from, to, card)
    return table.contains(U.getMark(from, "@@joy__juzhan-turn"), to.id)
    or (card and card.color == Card.Red and card.trueName == "slash" and table.contains(U.getMark(from, "joy__juzhan_red-turn"), to.id))
  end,
}
joy__juzhan:addRelatedSkill(joy__juzhan_prohibit)
yanyan:addSkill(joy__juzhan)
Fk:loadTranslationTable{
  ["joy__yanyan"] = "严颜",
  ["#joy__yanyan"] = "断头将军",

  ["joy__juzhan"] = "拒战",
  [":joy__juzhan"] = "当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能再对你使用牌；当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能对其使用红色【杀】。",
  ["@@joy__juzhan-turn"] = "拒战",

  ["~yanyan"] = "宁可断头死，安能屈膝降！",
  ["$joy__juzhan1"] = "砍头便砍头，何为怒耶！",
  ["$joy__juzhan2"] = "我州但有断头将军，无降将军也！",
}





Fk:loadTranslationTable{
  ["joy__yuji"] = "于吉",
  ["joy__guhuo"] = "蛊惑",
  [":joy__guhuo"] = "每回合限一次，当你使用伤害牌结算后，你摸一张牌；若此牌未造成伤害，则将此牌移出游戏，本回合结束后获得之。",
}

Fk:loadTranslationTable{
  ["joy__zuoci"] = "左慈",
  ["joy__shendao"] = "神道",
  [":joy__shendao"] = "你的判定牌生效前，你可以将判定结果修改为任意花色。",
  ["joy__xinsheng"] = "新生",
  [":joy__xinsheng"] = "当你受到伤害后，你可以亮出牌堆顶三张牌，然后获得其中花色不同的牌各一张。",
}


-- 阴

local wangji = General(extension, "joyex__wangji", "wei", 3)
local joyex__qizhi = fk.CreateTriggerSkill{
  name = "joyex__qizhi",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase ~= Player.NotActive and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isNude() and not table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__qizhi-choose:::"..data.card:getTypeString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@joyex__qizhi-turn", 1)
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    local type = Fk:getCardById(id).type
    room:throwCard({id}, self.name, to, player)
    if type == data.card.type and not player.dead then
      player:drawCards(1, self.name)
    elseif type ~= data.card.type and not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
local joyex__jinqu = fk.CreateTriggerSkill{
  name = "joyex__jinqu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:getHandcardNum() - player:usedSkillTimes("joyex__qizhi", Player.HistoryTurn) - 1
    if n > 0 then
      player.room:askForDiscard(player, n, n, false, self.name, false)
    end
    return true
  end,
}
wangji:addSkill(joyex__qizhi)
wangji:addSkill(joyex__jinqu)
Fk:loadTranslationTable{
  ["joyex__wangji"] = "界王基",
  ["joyex__qizhi"] = "奇制",
  [":joyex__qizhi"] = "当你于回合内使用基本牌或锦囊牌指定目标后，你可以弃置不为此牌目标的一名角色一张牌。若弃置的牌与你使用的牌类型相同，"..
  "你摸一张牌；类型不同，其摸一张牌。",
  ["joyex__jinqu"] = "进趋",
  [":joyex__jinqu"] = "弃牌阶段开始前，你可以跳过此阶段并摸两张牌，然后将手牌弃至X张（X为你本回合发动〖奇制〗次数+1）。",
  ["@joyex__qizhi-turn"] = "奇制",
  ["#joyex__qizhi-choose"] = "奇制：弃置一名角色一张牌，若为%arg，你摸一张牌，否则其摸一张牌",
}

local joyex__weiyan = General(extension, "joyex__weiyan", "shu", 4)
local joyex__kuanggu = fk.CreateTriggerSkill{
  name = "joyex__kuanggu",
  anim_type = "drawcard",
  events = {fk.Damage},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      self:doCost(event, target, player, data)
      if self.cost_data == "Cancel" or player.dead then break end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choices = {"draw1", "Cancel"}
    if player:isWounded() then
      table.insert(choices, 2, "recover")
    end
    self.cost_data = room:askForChoice(player, choices, self.name)
    return self.cost_data ~= "Cancel"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "recover" then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    elseif self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    end
  end,
}
local joyex__qimou_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__qimou_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      return player:getMark("@joyex__qimou-turn") or 0
    end
  end,
}
local joyex__qimou_distance = fk.CreateDistanceSkill{
  name = "#joyex__qimou_distance",
  correct_func = function(self, from, to)
    return -from:getMark("@joyex__qimou-turn")
  end,
}
local joyex__qimou = fk.CreateActiveSkill{
  name = "joyex__qimou",
  anim_type = "offensive",
  card_num = 0,
  target_num = 0,
  frequency = Skill.Limited,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = Self.hp,
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and player.hp > 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local tolose = self.interaction.data
    room:loseHp(player, tolose, self.name)
    if player.dead then return end
    room:setPlayerMark(player, "@joyex__qimou-turn", tolose)
    player:drawCards(1, self.name)
  end,
}
joyex__qimou:addRelatedSkill(joyex__qimou_targetmod)
joyex__qimou:addRelatedSkill(joyex__qimou_distance)
joyex__weiyan:addSkill(joyex__kuanggu)
joyex__weiyan:addSkill(joyex__qimou)
Fk:loadTranslationTable{
  ["joyex__weiyan"] = "界魏延",
  ["#joyex__weiyan"] = "嗜血的独狼",

  ["joyex__kuanggu"] = "狂骨",
  [":joyex__kuanggu"] = "你对一名角色造成1点伤害后，你可以选择摸一张牌或回复1点体力。",
  ["joyex__qimou"] = "奇谋",
  [":joyex__qimou"] = "限定技，出牌阶段，你可以失去X点体力，摸1张牌，本回合内与其他角色计算距离-X且可以多使用X张杀。",
  ["@joyex__qimou-turn"] = "奇谋",
}


local liushan = General(extension, "joy__liushan", "shu", 4)
local fangquan = fk.CreateTriggerSkill{
  name = "joy__fangquan",
  anim_type = "support",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:skip(Player.Play)
    player.room:setPlayerMark(player, "joy__fangquan_extra", 1)
    return true
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("joy__fangquan_extra") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "joy__fangquan_extra", 0)
    local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#joy__fangquan-give", self.name,false)
    room:getPlayerById(tos[1]):gainAnExtraTurn()
    
  end,
}
local ruoyu = fk.CreateTriggerSkill{
  name = "joy__ruoyu$",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
      player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    return table.every(player.room:getOtherPlayers(player), function(p) return p.hp >= player.hp end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then 
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name,
      })
    end
    room:handleAddLoseSkills(player, "joy__jijiang", nil, true, false)
  end,
}
local jijiang = fk.CreateViewAsSkill{
  name = "joy__jijiang$",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = Util.FalseFunc,
  view_as = function(self, cards)
    if #cards ~= 0 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    return c
  end,
  before_use = function(self, player, use)
    local room = player.room
    if use.tos then
      room:doIndicate(player.id, TargetGroup:getRealTargets(use.tos))
    end

    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.kingdom == "shu" then
        local cardResponded = room:askForResponse(p, "slash", "slash", "#joy__jijiang-ask:" .. player.id, true)
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          use.card = cardResponded
          if not p.dead and not player.dead then
            player:drawCards(1,self.name)
            p:drawCards(1,self.name)
          end
          return
        end
      end
    end

    room:setPlayerMark(player, "joy__jijiang-failed-phase", 1)
    return self.name
  end,
  enabled_at_play = function(self, player)
    return player:getMark("joy__jijiang-failed-phase") == 0 and not table.every(Fk:currentRoom().alive_players, function(p)
      return p == player or p.kingdom ~= "shu"
    end)
  end,
  enabled_at_response = function(self, player)
    return not table.every(Fk:currentRoom().alive_players, function(p)
      return p == player or p.kingdom ~= "shu"
    end)
  end,
}
liushan:addSkill("xiangle")
liushan:addSkill(fangquan)
liushan:addSkill(ruoyu)
liushan:addRelatedSkill(jijiang)
Fk:loadTranslationTable{
  ["joy__liushan"] = "刘禅",
  ["#joy__liushan"] = "无为的真命主",

  ["joy__fangquan"] = "放权",
  [":joy__fangquan"] = "你可以跳过你的出牌阶段，然后此回合结束时，令一名其他角色进行一个额外的回合。",
  ["#joy__fangquan-give"] = "选择一名其他角色进行一个额外的回合",
  ["joy__ruoyu"] = "若愚",
  [":joy__ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值为场上最小的角色，你增加1点体力上限，回复1点体力，然后获得“激将”。",
  ["joy__jijiang"] = "激将",
  [":joy__jijiang"] = "主公技，其他蜀势力角色可以在你需要时代替你使用或打出【杀】，若以此法出【杀】，则你与其各摸一张牌。",

  ["#joy__jijiang-ask"] =  "激将：你可代替 %src 打出一张杀，然后其与你各摸一张牌"

}

return extension
