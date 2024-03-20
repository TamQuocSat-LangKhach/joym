local extension = Package("joy_ex")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ex"] = "欢乐-界标",
  ["joyex"] = "欢乐界",
}

local U = require "packages/utility/utility"

local caocao = General:new(extension, "joyex__caocao", "wei", 4)
local jianxiong = fk.CreateTriggerSkill{
  name = "joyex__jianxiong",
  anim_type = "masochism",
  events = {fk.Damaged},
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or player.dead then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local choice = player.room:askForChoice(player, {"joyex__jianxiong_prey", "draw2"}, self.name)
    if choice == "joyex__jianxiong_prey" then
      player:drawCards(1, self.name)
      if not player.dead and data.card and player.room:getCardArea(data.card) == Card.Processing then
        player.room:obtainCard(player.id, data.card, true, fk.ReasonPrey)
      end
    else
      player:drawCards(2, self.name)
    end
  end,
}

local hujia = fk.CreateTriggerSkill{
  name = "joyex__hujia$",
  anim_type = "defensive",
  events = {fk.AskForCardUse, fk.AskForCardResponse},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none"))) and
      (data.extraData == nil or data.extraData.hujia_ask == nil) and
      not table.every(player.room.alive_players, function(p)
        return p == player or p.kingdom ~= "wei"
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p:isAlive() and p.kingdom == "wei" then
        local cardResponded = room:askForResponse(p, "jink", "jink", "#joyex__hujia-ask:" .. player.id, true, {hujia_ask = true})
        if cardResponded then
          room:responseCard({
            from = p.id,
            card = cardResponded,
            skipDrop = true,
          })

          if event == fk.AskForCardUse then
            data.result = {
              from = player.id,
              card = Fk:cloneCard('jink'),
            }
            data.result.card:addSubcards(room:getSubcardsByRule(cardResponded, { Card.Processing }))
            data.result.card.skillName = self.name

            if data.eventData then
              data.result.toCard = data.eventData.toCard
              data.result.responseToEvent = data.eventData.responseToEvent
            end
          else
            data.result = Fk:cloneCard('jink')
            data.result:addSubcards(room:getSubcardsByRule(cardResponded, { Card.Processing }))
            data.result.skillName = self.name
          end
          if player:getMark("joyex__hujia-turn") == 0 then
            if p.room:askForSkillInvoke(p,self.name,nil,"#joyex__hujia-drawcard:" .. player.id) and not player.dead then
              player.room:drawCards(player,1,self.name)
              player.room:setPlayerMark(player,"joyex__hujia-turn",1)
            end
          end
          return true
        end
      end
    end
  end,
}

caocao:addSkill(jianxiong)
caocao:addSkill(hujia)
Fk:loadTranslationTable{
  ["joyex__caocao"] = "界曹操",

  ["joyex__jianxiong"] = "奸雄",
  [":joyex__jianxiong"] = "当你每受到1点伤害后，你可以摸一张牌并获得对你造成伤害的牌；或摸两张牌",
  ["joyex__hujia"] = "护驾",
  [":joyex__hujia"] = "主公技，其他魏势力角色可以替你使用或打出【闪】。"..
  "其他魏势力角色若以此法使用或打出【闪】时，可以令你摸一张牌，每回合限一张。",

  ["joyex__jianxiong_prey"] = "摸一张牌，获得对你造成伤害的牌",
  ["#joyex__hujia-ask"] = "护驾:是否为 %src 打出一张闪,若打出可令其摸一张牌(每回合限一张)。",
  ["#joyex__hujia-drawcard"] = "护驾:是否令 %src 摸一张牌？"
}

local simayi = General(extension, "joyex__simayi", "wei", 3)
local joyex__guicai = fk.CreateTriggerSkill{
  name = "joyex__guicai",
  anim_type = "control",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local card = player.room:askForResponse(player, self.name, ".|.|.|hand,equip|.|", "#joyex__guicai-ask::" .. target.id .. ":" .. data.reason, true)
    if card ~= nil then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(self.cost_data, player, data, self.name)
    if player.dead then return end
    if self.cost_data.suit == Card.Club then
      player:drawCards(2, self.name)
    elseif self.cost_data.suit == Card.Heart and player:isWounded() then
      player.room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = self.name
      })
    end
  end,
}
local joyex__fankui = fk.CreateTriggerSkill{
  name = "joyex__fankui",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if self.cancel_cost or player.dead then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, data) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.suit == Card.Heart then
      local targets = table.map(table.filter(room.alive_players, function(p) return not p:isNude() end), Util.IdMapper)
      if #targets == 0 then return end
      local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__fankui-choose", self.name, false)
      local to = room:getPlayerById(tos[1])
      local card = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card, false, fk.ReasonPrey)
    else
      local from = data.from
      if from and not from.dead and not from:isNude() then
        room:doIndicate(player.id, {from.id})
        local card = room:askForCardChosen(player, from, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    end
  end,
}
simayi:addSkill(joyex__guicai)
simayi:addSkill(joyex__fankui)
Fk:loadTranslationTable{
  ["joyex__simayi"] = "界司马懿",
  ["joyex__guicai"] = "鬼才",
  [":joyex__guicai"] = "任何判定牌生效前，你可以打出一张牌代替之，若此牌为红桃，你回复1点体力，若此牌为梅花，你摸两张牌。",
  ["joyex__fankui"] = "反馈",
  [":joyex__fankui"] = "当你受到1点伤害后，你可以进行判定：红桃，你获得场上任意角色的一张牌；其他花色，你获得伤害来源一张牌。",

  ["#joyex__guicai-ask"] = "鬼才：你可打出一张牌代替 %dest 的 %arg 判定;若为红桃，你回复1点体力，若为梅花，你摸两张牌。",
  ["#joyex__fankui-choose"] = "反馈：获得一名角色的一张牌。",

  ["$joyex__guicai1"] = "天命难违？哈哈哈哈哈……",
  ["$joyex__guicai2"] = "才通天地，逆天改命！",
  ["$joyex__fankui1"] = "哼，自作孽不可活！",
  ["$joyex__fankui2"] = "哼，正中下怀！",
  ["~joyex__simayi"] = "我的气数，就到这里了么？",
}

local joyex__guojia = General(extension, "joyex__guojia", "wei", 3)

local checkShenglunMark = function (player)
  local mark = player.dead and 0 or ("胜"..player:getMark("joy__shenglun_win").." 败"..player:getMark("joy__shenglun_lose"))
  player.room:setPlayerMark(player, "@joy__shenglun", mark)
end

local joy__shenglun = fk.CreateActiveSkill{
  name = "joy__shenglun",
  anim_type = "control",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected < 2 and Self.id ~= to_select
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    for _, pid in ipairs(effect.tos) do
      local to = room:getPlayerById(pid)
      local list = {
        player.hp - to.hp,
        player:getHandcardNum() - to:getHandcardNum(),
        #player:getEquipments(Card.SubtypeWeapon)-#to:getEquipments(Card.SubtypeWeapon),
        #player:getEquipments(Card.SubtypeArmor)-#to:getEquipments(Card.SubtypeArmor),
        (#player:getEquipments(Card.SubtypeDefensiveRide)+#player:getEquipments(Card.SubtypeOffensiveRide)) -
        (#to:getEquipments(Card.SubtypeDefensiveRide)+#to:getEquipments(Card.SubtypeOffensiveRide)),
      }
      for _, n in ipairs(list) do
        if n > 0 then
          room:addPlayerMark(player, "joy__shenglun_win")
        else
          room:addPlayerMark(player, "joy__shenglun_lose")
        end
      end
    end
    checkShenglunMark(player)
    local yiji = Fk.skills["ex__yiji"]
    if player:getMark("joy__shenglun_win") > 9 then
      if player:isWounded() then
        room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
        if player.dead then return end
      end
      room:useSkill(player, yiji, function()
        return yiji:use(fk.Damaged, player, player, {to = player, num = 1})
      end)
      room:setPlayerMark(player, "joy__shenglun_win", 0)
      checkShenglunMark(player)
    end
    if player.dead then return end
    if player:getMark("joy__shenglun_lose") > 9 then
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#joy__shenglun-damage", self.name, false)
      room:damage { from = player, to = room:getPlayerById(tos[1]), damage = 1, skillName = self.name }
      if player.dead then return end
      room:useSkill(player, yiji, function()
        return yiji:use(fk.Damaged, player, player, {to = player, num = 1})
      end)
      room:setPlayerMark(player, "joy__shenglun_lose", 0)
      checkShenglunMark(player)
    end
  end,
}
joyex__guojia:addSkill(joy__shenglun)
joyex__guojia:addSkill("tiandu")
joyex__guojia:addSkill("ex__yiji")

Fk:loadTranslationTable{
  ["joyex__guojia"] = "界郭嘉",
  ["joy__shenglun"] = "胜论",
  [":joy__shenglun"] = "出牌阶段限一次，你可以选择至多两名其他角色，你依次与这些角色比较体力、手牌、武器、防具、坐骑的数量（数量大于其为胜，否则为负），若胜或败累计达到10次，胜：你回复1点体力，败：你对一名角色造成1点伤害。然后发动一次“遗计”并重置对应的胜败次数。",
  ["@joy__shenglun"] = "胜论",
  ["#joy__shenglun-damage"] = "胜论：对一名角色造成1点伤害",
}


local zhaoyun = General:new(extension, "joyex__zhaoyun", "shu", 4)
local yajiao = fk.CreateTriggerSkill{
  name = "joyex__yajiao",
  anim_type = "control",
  events = {fk.CardUsing, fk.CardResponding, fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and target == player then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish and player:usedSkillTimes("ex__longdan", Player.HistoryTurn) > 0
      else
        return U.IsUsingHandcard(player, data) and player ~= player.room.current
      end
    end
  end,
  on_cost = function(self,event,target,player,data)
    if event == fk.EventPhaseStart then
      return true
    else
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:drawCards(1 ,self.name)
    else
      local cards = room:getNCards(1)
      player:showCards(cards)
      local tos = room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, "#joyex__yajiao-choose:::"..Fk:getCardById(cards[1]):toLogString(), self.name, false)
      if #tos > 0 then
        local to = room:getPlayerById(tos[1])
        room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, self.name, nil, true, player.id)
      end
    end
  end,
}
zhaoyun:addSkill("ex__longdan")
zhaoyun:addSkill(yajiao)
Fk:loadTranslationTable{
  ["joyex__zhaoyun"] = "界赵云",
  ["joyex__yajiao"] = "涯角",
  [":joyex__yajiao"] = "每当你于回合外使用或打出手牌时，你可以展示牌堆顶一张牌并交给一名角色；结束阶段，若你于本回合发动过【龙胆】，你摸一张牌。",
  ["#joyex__yajiao-choose"] = "涯角: 将 %arg 交给一名角色",
}


local guanyu = General:new(extension, "joyex__guanyu", "shu", 4)
local wusheng = fk.CreateViewAsSkill{
  name = "joyex__wusheng",
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Red
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("slash")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local wusheng_trigger = fk.CreateTriggerSkill{
  name = "#joyex__wusheng_trigger",
  main_skill = wusheng,
  mute = true,
  events = {fk.TurnStart, fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      return (event == fk.TurnStart) or (data.card.trueName == "slash" and data.card.color == Card.Red)
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, "joyex__wusheng", "drawcard")
      local ids = room:getCardsFromPileByRule(".|.|heart,diamond", 1, "allPiles")
      if #ids > 0 then
        room:obtainCard(player, ids[1], false, fk.ReasonPrey)
      end
    else
      room:notifySkillInvoked(player, "joyex__wusheng", "offensive")
      data.additionalDamage = (data.additionalDamage or 0) + 1
    end
  end,
}
local joy__tuodao = fk.CreateTriggerSkill{
  name = "joy__tuodao",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.CardUseFinished, fk.CardRespondFinished},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.name == "jink"
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@joy__tuodao")
  end,

  refresh_events = {fk.CardUsing},
  can_refresh = function (self, event, target, player, data)
    return player == target and data.card.trueName == "slash" and player:getMark("@joy__tuodao") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@joy__tuodao")
    player.room:setPlayerMark(player, "@joy__tuodao", 0)
  end,
}
wusheng:addRelatedSkill(wusheng_trigger)
guanyu:addSkill(wusheng)
guanyu:addSkill(joy__tuodao)
guanyu:addSkill("guanjue")
Fk:loadTranslationTable{
  ["joyex__guanyu"] = "界关羽",
  ["#joyex__guanyu"] = "美髯公",
  ["joyex__wusheng"] = "武圣",
  [":joyex__wusheng"] = "回合开始时，你获得一张红色牌；你可以将一张红色牌当做【杀】使用或打出；你使用的红色【杀】伤害+1。",
  ["#joyex__wusheng_trigger"] = "武圣",
  ["joy__tuodao"] = "拖刀",
  [":joy__tuodao"] = "锁定技，每当你使用或打出一张【闪】后，令你下一张使用的【杀】伤害+1。",
  ["@joy__tuodao"] = "拖刀",
}


local joyex__tieji = fk.CreateTriggerSkill{
  name = "joyex__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    room:addPlayerMark(to, "@@joytieji-turn")
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    local judge = {
      who = player,
      reason = self.name,
      pattern = ".",
    }
    room:judge(judge)
    if judge.card.color == Card.Red then
      data.disresponsive = true
    elseif judge.card.color == Card.Black then
      if not player.dead then
        player:drawCards(2, self.name)
      end
    end
  end,
}

local joyex__machao = General:new(extension, "joyex__machao", "shu", 4)
joyex__machao:addSkill("joy__yuma")
joyex__machao:addSkill(joyex__tieji)
Fk:loadTranslationTable{
  ["joyex__machao"] = "界马超",
  ["joyex__tieji"] = "铁骑",
  [":joyex__tieji"] = "当你使用【杀】指定目标后，你可令其本回合非锁定技失效，然后你进行判定，若为红色，该角色不能使用【闪】；黑色，你摸两张牌。",
  ["joyex__tieji_invalidity"] = "铁骑",
  ["@@joytieji-turn"] = "铁骑",
}

local huangyueying = General(extension, "joyex__huangyueying", "shu", 3, 3, General.Female)
local joyex__jizhi = fk.CreateTriggerSkill{
  name = "joyex__jizhi",
  anim_type = "drawcard",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.type == Card.TypeTrick
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:getCardById(player:drawCards(1)[1])
    if card.type == Card.TypeBasic then
      room:addPlayerMark(player, MarkEnum.AddMaxCardsInTurn, 1)
    elseif card.type == Card.TypeEquip and room:getCardOwner(card) == player and room:getCardArea(card) == Player.Hand then
      local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
        return p:hasEmptyEquipSlot(card.sub_type) end), function(p) return p.id end)
      if #targets == 0 then return end
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__jizhi-choose:::"..card:toLogString(), self.name, true)
      if #to > 0 then
        room:moveCards({
          ids = {card:getEffectiveId()},
          from = player.id,
          to = to[1],
          toArea = Card.PlayerEquip,
          moveReason = fk.ReasonPut,
          proposer = player.id,
          skillName = self.name,
        })
      end
    elseif card.type == Card.TypeTrick and player.phase == Player.Play then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", 1)
    end
  end,
}
local joyex__qicai = fk.CreateTriggerSkill{
  name = "joyex__qicai",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.BeforeCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and (player:getEquipment(Card.SubtypeWeapon) or player:getEquipment(Card.SubtypeArmor)) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard and (not move.proposer or move.proposer ~= player.id) then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerEquip and
              table.contains({Card.SubtypeWeapon, Card.SubtypeArmor}, Fk:getCardById(info.cardId).sub_type) then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local ids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard and (not move.proposer or move.proposer ~= player.id) then
        local move_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if info.fromArea == Card.PlayerEquip and table.contains({Card.SubtypeWeapon, Card.SubtypeArmor}, Fk:getCardById(id).sub_type) then
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #ids > 0 then
          move.moveInfo = move_info
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#cancelDismantle",
        card = ids,
        arg = self.name,
      }
    end
  end,
}
local joyex__qicai_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__qicai_targetmod",
  main_skill = joyex__qicai,
  bypass_distances = function(self, player, skill, card)
    return player:hasSkill("joyex__qicai") and card and card.type == Card.TypeTrick
  end,
}
joyex__qicai:addRelatedSkill(joyex__qicai_targetmod)
huangyueying:addSkill(joyex__jizhi)
huangyueying:addSkill(joyex__qicai)
Fk:loadTranslationTable{
  ["joyex__huangyueying"] = "界黄月英",
  ["joyex__jizhi"] = "集智",
  [":joyex__jizhi"] = "当你使用一张锦囊牌时，你可以摸一张牌，若此牌为：基本牌，你本回合手牌上限+1；装备牌，你可以将之置入一名其他角色装备区；"..
  "锦囊牌，你本阶段使用【杀】次数上限+1。",
  ["joyex__qicai"] = "奇才",
  [":joyex__qicai"] = "锁定技，你使用锦囊牌无距离限制；其他角色不能弃置你装备区里的防具和武器牌。",
  ["#joyex__jizhi-choose"] = "集智：你可以将%arg置入一名其他角色装备区",
}

local sunquan = General(extension, "joyex__sunquan", "wu", 4)
local zhiheng = fk.CreateActiveSkill{
  name = "joyex__zhiheng",
  anim_type = "drawcard",
  min_card_num = 1,
  card_filter = function(self, to_select, selected)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 1 + player:getMark("joyex__zhiheng-phase")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local hand = player:getCardIds(Player.Hand)
    local more = #hand > 0 and table.every(hand, function(id) return table.contains(effect.cards, id) end)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local cards = player:drawCards(#effect.cards + (more and 1 or 0), self.name)
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 1
    and table.every(cards, function(id) return Fk:getCardById(id).sub_type ~= Card.SubtypeDelayedTrick end) then
      room:addPlayerMark(player, "joyex__zhiheng-phase")
    end
    if player:usedSkillTimes(self.name, Player.HistoryPhase) == 2
    and table.every(cards, function(id) return Fk:getCardById(id).type == Card.TypeBasic end) then
      room:addPlayerMark(player, "joyex__zhiheng-phase")
    end
  end
}
local jiuyuan = fk.CreateTriggerSkill{
  name = "joyex__jiuyuan$",
  anim_type = "support",
  events = {fk.PreHpRecover, fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      return target ~= player and player:hasSkill(self) and player:isWounded()
      and target.kingdom == "wu" and target == player.room.current
    else
      return target ~= player and player:hasSkill(self) and player.dying
      and target.kingdom == "wu" and data.card.name == "peach"
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.TargetSpecified then return true end
    return player.room:askForSkillInvoke(target, self.name, nil, "#ex__jiuyuan-ask::"..player.id)
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.PreHpRecover then
      player.room:recover{ who = player, num = 1, skillName = self.name, recoverBy = target }
      if not target.dead then
        target:drawCards(1, self.name)
      end
      return true
    else
      data.additionalRecover = (data.additionalRecover or 0) + 1
    end
  end,
}
sunquan:addSkill(zhiheng)
sunquan:addSkill(jiuyuan)
Fk:loadTranslationTable{
  ["joyex__sunquan"] = "界孙权",
  ["joyex__zhiheng"] = "制衡",
  [":joyex__zhiheng"] = "出牌阶段限一次，你可以弃置至少一张牌，然后摸等量的牌。若你以此法弃置了所有的手牌，则额外摸一张牌，若你本阶段第一次以此法获得的牌不含延时锦囊牌，则本阶段此技能使用次数+1；若你本阶段第二次以此法获得的牌均为基本牌，则本阶段此技能使用次数+1。",
  ["joyex__jiuyuan"] = "救援",
  [":joyex__jiuyuan"] = "主公技，其他吴势力角色于其回合内回复体力前，该角色可以改为令你回复1点体力，然后其摸一张牌。其他吴势力武将使用【桃】指定你为目标后，若你处于濒死状态，此【桃】回复体力值+1。",
}

local huanggai = General(extension, "joyex__huanggai", "wu", 4)
local zhaxiang = fk.CreateTriggerSkill{
  name = "joyex__zhaxiang",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardUseDeclared},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      data.card.trueName == "slash" and data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
}
local zhaxiang_targetmod = fk.CreateTargetModSkill{
  name = "#joyex__zhaxiang_targetmod",
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:hasSkill(zhaxiang) then
      return 1
    end
    return 0
  end,
  bypass_distances = function(self, player, skill, card)
    return skill.trueName == "slash_skill" and card.color == Card.Red and player:hasSkill(zhaxiang)
  end,
}
zhaxiang:addRelatedSkill(zhaxiang_targetmod)
huanggai:addSkill("kurou")
huanggai:addSkill(zhaxiang)
Fk:loadTranslationTable{
  ["joyex__huanggai"] = "界黄盖",
  ["joyex__zhaxiang"] = "诈降",
  [":joyex__zhaxiang"] = "锁定技，你使用【杀】次数上限+1、使用红色【杀】无距离限制且不可被响应。",
}

local lvmeng = General(extension, "joyex__lvmeng", "wu", 4)
local keji = fk.CreateTriggerSkill{
  name = "joy__keji",
  anim_type = "defensive",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and data.to == Player.Discard then
      local play_ids = {}
      player.room.logic:getEventsOfScope(GameEvent.Phase, 1, function (e)
        if e.data[2] == Player.Play and e.end_id then
          table.insert(play_ids, {e.id, e.end_id})
        end
        return false
      end, Player.HistoryTurn)
      if #play_ids == 0 then return true end
      local function PlayCheck (e)
        local in_play = false
        for _, ids in ipairs(play_ids) do
          if e.id > ids[1] and e.id < ids[2] then
            in_play = true
            break
          end
        end
        return in_play and e.data[1].from == player.id and e.data[1].card.trueName == "slash"
      end
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, PlayCheck, Player.HistoryTurn) == 0
      and #player.room.logic:getEventsOfScope(GameEvent.RespondCard, 1, PlayCheck, Player.HistoryTurn) == 0
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1,self.name)
    return true
  end
}
local qinxue = fk.CreateTriggerSkill{
  name = "joyex__qinxue",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Finish and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return #player.player_cards[Player.Hand] >= player.hp*3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:isWounded() then
      local n = player.maxHp - player.hp
      room:changeMaxHp(player, -n)
    end
    room:handleAddLoseSkills(player, "-joy__keji", nil)
    room:handleAddLoseSkills(player, "joy__gongxin", nil)
  end,
}
lvmeng:addSkill(keji)
lvmeng:addSkill(qinxue)
lvmeng:addRelatedSkill("joy__gongxin")
Fk:loadTranslationTable{
  ["joyex__lvmeng"] = "界吕蒙",

  ["joy__keji"] = "克己",
  [":joy__keji"] = "若你未于出牌阶段内打出或使用过【杀】，你可以跳过弃牌阶段并摸一张牌。",
  ["joyex__qinxue"] = "勤学",
  [":joyex__qinxue"] = "觉醒技，结束阶段，若你的手牌数大于等于体力值的3倍，你将体力上限减少至当前体力值，然后获得技能〖攻心〗失去〖克己〗。",
}

local luxun = General(extension, "joyex__luxun", "wu", 3)
local qianxun = fk.CreateTriggerSkill{
  name = "joyex__qianxun",
  events = {fk.CardEffecting},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target == player and data.card.type == Card.TypeTrick and #TargetGroup:getRealTargets(data.tos) == 1
    and not player:isKongcheng() and player.hp > 0
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForCard(player,1,player.hp,false,self.name,true,".","#joyex__qianxun-card:::"..player.hp)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile("joyex__qianxun", self.cost_data, false, self.name)
  end,
}
local qianxun_delay = fk.CreateTriggerSkill{
  name = "#joyex__qianxun_delay",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return #player:getPile("joyex__qianxun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:moveCardTo(player:getPile("joyex__qianxun"), Card.PlayerHand, player, fk.ReasonPrey, self.name)
  end,
}
qianxun:addRelatedSkill(qianxun_delay)
luxun:addSkill(qianxun)
local lianying = fk.CreateTriggerSkill{
  name = "joyex__lianying",
  anim_type = "drawcard",
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if not player:isKongcheng() then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2,self.name)
    if player.dead or player:isKongcheng() then return end
    local tos, card = room:askForChooseCardAndPlayers(player,table.map(player.room:getOtherPlayers(player), Util.IdMapper),
    1,1,".|.|.|hand","#joyex__lianying-choose",self.name,true)
    if #tos > 0 then
      room:moveCardTo(card, Player.Hand, room:getPlayerById(tos[1]), fk.ReasonGive, self.name, nil, false, player.id)
    end
  end,
}
luxun:addSkill(lianying)

Fk:loadTranslationTable{
  ["joyex__luxun"] = "界陆逊",

  ["joyex__qianxun"] = "谦逊",
  [":joyex__qianxun"] = "当一张锦囊牌对你生效时，若你是此牌唯一目标，则你可以将至多X张手牌扣置于武将牌上（X为你的体力值），然后此回合结束时，你获得这些牌。",
  ["joyex__lianying"] = "连营",
  [":joyex__lianying"] = "当你失去手牌后，若你没有手牌，你可以摸两张牌，然后你可以将一张手牌交给一名其他角色。",
  ["#joyex__lianying-choose"] = "连营：你可以将一张手牌交给一名其他角色",
  ["#joyex__qianxun-card"] = "谦逊：你可以将至多 %arg 张手牌扣置武将牌上",
  ["#joyex__qianxun_delay"] = "谦逊",
}

local diaochan = General(extension, "joyex__diaochan", "qun", 3, 3, General.Female)
local joyex__lijian = fk.CreateActiveSkill{
  name = "joyex__lijian",
  anim_type = "offensive",
  card_num = 1,
  target_num = 2,
  prompt = "#joyex__lijian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, cards)
    if #cards ~= 1 then return false end
    local target = Fk:currentRoom():getPlayerById(to_select)
    if target:getMark("joyex__lijian-turn") == 0 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isProhibited(Fk:currentRoom():getPlayerById(selected[1]), Fk:cloneCard("duel"))
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    room:useVirtualCard("duel", nil, room:getPlayerById(effect.tos[2]), room:getPlayerById(effect.tos[1]), self.name)
  end,
}
local joyex__lijian_trigger = fk.CreateTriggerSkill{
  name = "#joyex__lijian_trigger",
  refresh_events = {fk.PreDamage},
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card and table.contains(data.card.skillNames, joyex__lijian.name)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(data.to, "joyex__lijian-turn", 1)
  end,
}
local joyex__biyue = fk.CreateTriggerSkill{
  name = "joyex__biyue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1 + player:usedSkillTimes("joyex__lijian", Player.HistoryTurn), self.name)
  end,
}
joyex__lijian:addRelatedSkill(joyex__lijian_trigger)
diaochan:addSkill(joyex__lijian)
diaochan:addSkill(joyex__biyue)
Fk:loadTranslationTable{
  ["joyex__diaochan"] = "界貂蝉",
  ["joyex__lijian"] = "离间",
  [":joyex__lijian"] = "出牌阶段限两次，你可以弃置一张牌并选择两名角色，视为其中一名角色对另一名角色使用一张【决斗】，此【决斗】失败的角色角色本回合无法成为〖离间〗的目标。",
  ["joyex__biyue"] = "闭月",
  [":joyex__biyue"] = "结束阶段，你摸X张牌（X为本回合你发动〖离间〗次数+1）。",
  ["#joyex__lijian"] = "离间：弃置一张牌，选择两名角色，视为第二名角色对第一名角色使用【决斗】",
}


return extension
