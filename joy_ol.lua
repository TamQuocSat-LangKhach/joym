local extension = Package("joy_ol")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ol"] = "欢乐-OL改",
}

local U = require "packages/utility/utility"

-- 在OL武将基础上修改的武将

local joy__zhanglu = General(extension, "joy__zhanglu", "qun", 3)
local joy__yishe = fk.CreateTriggerSkill{
  name = "joy__yishe",
  anim_type = "support",
  derived_piles = "joy__zhanglu_mi",
  events = {fk.EventPhaseStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.EventPhaseStart then
        return target == player and player.phase == Player.Finish
      else
        if #player:getPile("joy__zhanglu_mi") == 0 and player:isWounded() then
          for _, move in ipairs(data) do
            if move.from == player.id then
              for _, info in ipairs(move.moveInfo) do
                if info.fromSpecialName == "joy__zhanglu_mi" then
                  return true
                end
              end
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if event == fk.EventPhaseStart then
      return player.room:askForSkillInvoke(player, self.name, nil, "#joy__yishe-invoke")
    else
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventPhaseStart then
      player:drawCards(2, self.name)
      if player:isNude() then return end
      local dummy = Fk:cloneCard("dilu")
      local cards = player:getCardIds("he")
      if #cards > 2 then
        cards = room:askForCard(player, 2, 2, true, self.name, false, ".", "#joy__yishe-cost")
      end
      dummy:addSubcards(cards)
      player:addToPile("joy__zhanglu_mi", dummy, true, self.name)
    else
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end,
}
local joy__bushi = fk.CreateTriggerSkill{
  name = "joy__bushi",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or data.from == player) and #player:getPile("joy__zhanglu_mi") > 0
    and not (data.from.dead or data.to.dead)
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.damage do
      if #player:getPile("joy__zhanglu_mi") == 0 or data.from.dead or data.to.dead or self.cancel_cost then return end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    if player.room:askForSkillInvoke(player, self.name, nil, "#joy__bushi-invoke:"..target.id) then
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if #player:getPile("joy__zhanglu_mi") == 1 then
      room:obtainCard(target, player:getPile("joy__zhanglu_mi")[1], true, fk.ReasonPrey)
    else
      local card = room:askForCardChosen(player, player, { card_data = { { self.name, player:getPile("joy__zhanglu_mi") } } }, self.name, "#joy__bushi-card:"..target.id)
      room:obtainCard(target, card, true, fk.ReasonPrey, player.id)
    end
  end,
}
local joy__midao = fk.CreateTriggerSkill{
  name = "joy__midao",
  anim_type = "control",
  expand_pile = "joy__zhanglu_mi",
  events = {fk.AskForRetrial},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and #player:getPile("joy__zhanglu_mi") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local card = room:askForCard(player, 1, 1, false, self.name, true, ".|.|.|joy__zhanglu_mi",
    "#joy__midao-choose::" .. target.id..":"..data.reason, "joy__zhanglu_mi")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:retrial(Fk:getCardById(self.cost_data), player, data, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
joy__zhanglu:addSkill(joy__yishe)
joy__zhanglu:addSkill(joy__bushi)
joy__zhanglu:addSkill(joy__midao)
Fk:loadTranslationTable{
  ["joy__zhanglu"] = "张鲁",
  ["#joy__zhanglu"] = "政宽教惠",
  ["joy__yishe"] = "义舍",
  [":joy__yishe"] = "结束阶段开始时，你可以摸两张牌，然后将两张牌置于武将牌上，称为“米”。当“米”移至其他区域后，若你的武将牌上没有“米”，你回复1点体力。",
  ["joy__bushi"] = "布施",
  [":joy__bushi"] = "当你受到1点伤害后，或其他角色受到你造成的1点伤害后，你可以将一张“米”交给受到伤害的角色。",
  ["joy__midao"] = "米道",
  [":joy__midao"] = "当一张判定牌生效前，你可以打出一张“米”代替之，然后摸一张牌。",
  ["joy__zhanglu_mi"] = "米",
  ["#joy__yishe-invoke"] = "义舍：你可以摸两张牌，然后将两张牌置为“米”",
  ["#joy__yishe-cost"] = "义舍：将两张牌置为“米”",
  ["#joy__bushi-invoke"] = "布施：你可以将一张“米”交给 %src",
  ["#joy__bushi-card"] = "布施：选择一张“米”交给 %src",
  ["#joy__midao-choose"] = "米道：可以打出一张“米”修改 %dest 的“%arg”判定，并摸一张牌",
}


local caoying = General(extension, "joy__caoying", "wei", 4, 4, General.Female)
local lingren = fk.CreateTriggerSkill{
  name = "joy__lingren",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
    data.card.is_damage_card and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1, "#joy__lingren-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local choices = {"joy__lingren_basic", "joy__lingren_trick", "joy__lingren_equip"}
    local yes = room:askForChoices(player, choices, 0, 3, self.name, "#joy__lingren-choice::" .. self.cost_data, false)
    for _, value in ipairs(yes) do
      table.removeOne(choices, value)
    end
    local right = 0
    for _, id in ipairs(to.player_cards[Player.Hand]) do
      local str = "joy__lingren_"..Fk:getCardById(id):getTypeString()
      if table.contains(yes, str) then
        right = right + 1
        table.removeOne(yes, str)
      else
        table.removeOne(choices, str)
      end
    end
    right = right + #choices
    room:sendLog{
      type = "#joy__lingren_result",
      from = player.id,
      arg = tostring(right),
      toast = true,
    }
    if right > 0 then
      data.extra_data = data.extra_data or {}
      data.extra_data.lingren = data.extra_data.lingren or {}
      table.insert(data.extra_data.lingren, self.cost_data)
    end
    if right > 1 then
      player:drawCards(2, self.name)
    end
    if right > 2 then
      local skills = {}
      if not player:hasSkill("ex__jianxiong", true) then
        table.insert(skills, "ex__jianxiong")
      end
      if not player:hasSkill("joy__xingshang", true) then
        table.insert(skills, "joy__xingshang")
      end
      room:setPlayerMark(player, self.name, skills)
      room:handleAddLoseSkills(player, table.concat(skills, "|"), nil, true, false)
    end
  end,
}
local lingren_delay = fk.CreateTriggerSkill {
  name = "#joy__lingren_delay",
  mute = true,
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or target ~= player then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    return use.extra_data and use.extra_data.lingren and table.contains(use.extra_data.lingren, player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
  
  refresh_events = {fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("joy__lingren") ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local skills = player:getMark("joy__lingren")
    room:setPlayerMark(player, "joy__lingren", 0)
    room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, true, false)
  end,
}
local fujian = fk.CreateTriggerSkill {
  name = "joy__fujian",
  anim_type = "control",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    local to = table.random(targets)
    room:doIndicate(player.id, {to.id})
    U.viewCards(player, table.random(to.player_cards[Player.Hand], 1), self.name, "$ViewCardsFrom:"..to.id)
  end,
}
lingren:addRelatedSkill(lingren_delay)
caoying:addSkill(lingren)
caoying:addSkill(fujian)
caoying:addRelatedSkill("ex__jianxiong")
caoying:addRelatedSkill("joy__xingshang")
Fk:loadTranslationTable{
  ["joy__caoying"] = "曹婴",
  ["#joy__caoying"] = "龙城凤鸣",

  ["joy__lingren"] = "凌人",
  [":joy__lingren"] = "出牌阶段限一次，当你使用【杀】或伤害类锦囊牌指定目标后，你可以猜测其中一名目标角色的手牌区中是否有基本牌、锦囊牌或装备牌。"..
  "若你猜对：至少一项，此牌对其造成的伤害+1；至少两项，你摸两张牌；三项，你获得技能〖奸雄〗和〖行殇〗直到你的下个回合开始。",
  ["joy__fujian"] = "伏间",
  [":joy__fujian"] = "锁定技，结束阶段，你随机观看一名其他角色的一张手牌。",
  ["#joy__lingren-choose"] = "凌人：你可以猜测其中一名目标角色的手牌中是否有基本牌、锦囊牌或装备牌",
  ["#joy__lingren-choice"] = "凌人：猜测%dest的手牌中是否有基本牌、锦囊牌或装备牌",
  ["joy__lingren_basic"] = "有基本牌",
  ["joy__lingren_trick"] = "有锦囊牌",
  ["joy__lingren_equip"] = "有装备牌",
  ["#joy__lingren_result"] = "%from 猜对了 %arg 项",
  ["joy__lingren_delay"] = "凌人",
}


local longfeng = General(extension, "joy__wolongfengchu", "shu", 4)
local joy__youlong = fk.CreateViewAsSkill{
  name = "joy__youlong",
  switch_skill_name = "joy__youlong",
  anim_type = "switch",
  pattern = ".",
  prompt = function ()
    return "#joy__youlong-prompt"..Self:getSwitchSkillState("joy__youlong")
  end,
  interaction = function()
    local names = {}
    local mark = Self:getTableMark("@$joy__youlong")
    local isYang = Self:getSwitchSkillState("joy__youlong") == fk.SwitchYang
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if ((card.type == Card.TypeBasic and not isYang) or
        (card:isCommonTrick() and isYang)) and
        not card.is_derived and
        ((Fk.currentResponsePattern == nil and Self:canUse(card)) or
        (Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(card))) then
        if not table.contains(mark, card.trueName) then
          table.insertIfNeed(names, card.name)
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function (self, to_select, selected)
    return Self:getSwitchSkillState("joy__youlong") == fk.SwitchYin and #selected == 0
    and Fk:getCardById(to_select).type ~= Card.TypeBasic and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  view_as = function(self, cards)
    if not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    if Self:getSwitchSkillState("joy__youlong") == fk.SwitchYin then
      if #cards ~= 1 then return end
      card:setMark("joy__youlong_card", cards[1])
    end
    card.skillName = self.name
    return card
  end,
  before_use = function(self, player, use)
    local room = player.room
    local mark = player:getTableMark("@$joy__youlong")
    table.insert(mark, use.card.trueName)
    room:setPlayerMark(player, "@$joy__youlong", mark)
    local state = player:getSwitchSkillState(self.name, true, true)
    room:setPlayerMark(player, "joy__youlong_" .. state .. "-turn", 1)
    if state == "yin" then
      local id = use.card:getMark("joy__youlong_card")
      if id ~= 0 then
        room:throwCard(id, self.name, player, player)
      end
    else
      local choices = player:getAvailableEquipSlots()
      if #choices == 0 then return end
      local choice = room:askForChoice(player, choices, self.name, "#joy__youlong-choice", false, player.equipSlots)
      room:abortPlayerArea(player, choice)
    end
  end,
  enabled_at_play = function(self, player)
    local state = player:getSwitchSkillState(self.name, false, true)
    if player:getMark("joy__youlong_" .. state .. "-turn") == 0 or player:getMark("joy__youlong_levelup") > 0 then
      return state == "yin" or#player:getAvailableEquipSlots() > 0
    end
  end,
  enabled_at_response = function(self, player, response)
    if response then return end
    local state = player:getSwitchSkillState(self.name, false, true)
    local pat = state == "yin" and "basic" or "trick"
    if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):matchExp(".|0|nosuit|none|.|"..pat) then
      if player:getMark("joy__youlong_" .. state .. "-turn") == 0 or player:getMark("joy__youlong_levelup") > 0 then
        return state == "yin" or#player:getAvailableEquipSlots() > 0
      end
    end
  end,
}
local joy__luanfeng = fk.CreateTriggerSkill{
  name = "joy__luanfeng",
  frequency = Skill.Limited,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.maxHp >= player.maxHp and target.dying
    and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function (self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__luanfeng-invoke:"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:recover {
      who = target,
      num = 3 - target.hp,
      recoverBy = player,
      skillName = self.name,
    }
    local targets = {player}
    table.insertIfNeed(targets, target)
    for _, p in ipairs(targets) do
      if not p.dead then
        local slots = table.simpleClone(p.sealedSlots)
        table.removeOne(slots, Player.JudgeSlot)
        if #slots > 0 then
          room:resumePlayerArea(p, slots)
        end
      end
    end
    if not target.dead then
      local n = 6 - target:getHandcardNum()
      if n > 0 then
        target:drawCards(n, self.name)
      end
    end
    if player.dead then return end
    room:setPlayerMark(player, "joy__youlong_levelup", 1)
    room:setPlayerMark(player, "@$joy__youlong", 0)
  end,
}
longfeng:addSkill(joy__youlong)
longfeng:addSkill(joy__luanfeng)
Fk:loadTranslationTable{
  ["joy__wolongfengchu"] = "卧龙凤雏",
  ["#joy__wolongfengchu"] = "一匡天下",

  ["joy__youlong"] = "游龙",
  [":joy__youlong"] = "转换技，每回合各限一次，阳：你可以废除一个装备栏，视为使用一张未以此法使用过的普通锦囊牌；阴：你可以弃置一张非基本牌，视为使用一张未以此法使用过的基本牌。",
  ["joy__luanfeng" ] = "鸾凤",
  [":joy__luanfeng"] = "限定技，当一名角色进入濒死状态时，若其体力上限不小于你，" ..
  "你可令其将体力回复至3点，恢复你与其被废除的装备栏，令其手牌补至六张，" ..
  "然后去除〖游龙〗的回合次数限制，重置〖游龙〗使用过的牌名。",

  ["#joy__youlong-prompt0"] = "游龙：废除一个装备栏，视为使用一张未以此法使用过的普通锦囊牌",
  ["#joy__youlong-prompt1"] = "游龙：弃置一张非基本牌，视为使用一张未以此法使用过的基本牌",
  ["#joy__youlong-choice"] = "游龙: 请选择废除一个装备栏",
  ["@$joy__youlong"] = "游龙",
  ["#joy__luanfeng-invoke"] = "鸾凤：你可令 %src 将体力回复至3点，手牌补至六张",
}

local quyi = General(extension, "joy__quyi", "qun", 4)
local fuji = fk.CreateTriggerSkill{
  name = "joy__fuji",
  anim_type = "offensive",
  events = {fk.CardUsing, fk.Damage},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.CardUsing then
      return target == player and player:hasSkill(self) and not player:isRemoved() and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isRemoved() and p:distanceTo(player) < 3 end)
    else
      return target == player and player:hasSkill(self) and data.to ~= player and not data.to.dead
      and not table.contains(player:getTableMark("joy__fuji_record"), data.to.id)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      data.disresponsiveList = data.disresponsiveList or {}
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p:isRemoved() and p:distanceTo(player) < 3 then
          table.insertIfNeed(data.disresponsiveList, p.id)
        end
      end
    else
      room:addPlayerMark(data.to, "@@joyfuji")
      room:addPlayerMark(data.to, MarkEnum.UncompulsoryInvalidity)
      local mark = player:getTableMark("joy__fuji_record")
      table.insert(mark, data.to.id)
      room:setPlayerMark(player, "joy__fuji_record", mark)
    end
  end,

  refresh_events = {fk.TurnStart, fk.BuryVictim},
  can_refresh = function(self, event, target, player, data)
    if player:getMark("joy__fuji_record") == 0 then return end
    if event == fk.BuryVictim then
      return target == player
    else
      return target ~= player
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(player:getTableMark("joy__fuji_record")) do
      local p = room:getPlayerById(pid)
      room:removePlayerMark(p, "@@joyfuji")
      room:removePlayerMark(p,MarkEnum.UncompulsoryInvalidity)
    end
    room:setPlayerMark(player, "joy__fuji_record", 0)
  end,
}
local jiaozi = fk.CreateTriggerSkill{
  name = "joy__jiaozi",
  anim_type = "offensive",
  events = {fk.DamageCaused},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      table.every(player.room:getOtherPlayers(player), function(p)
        return player:getHandcardNum() >= p:getHandcardNum() end)
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
quyi:addSkill(fuji)
quyi:addSkill(jiaozi)
Fk:loadTranslationTable{
  ["joy__quyi"] = "麴义",
  ["#joy__quyi"] = "名门的骁将",

  ["joy__fuji"] = "伏骑",
  ["#joy__fuji_mark"] = "伏骑",
  [":joy__fuji"] = "锁定技，当你使用【杀】或普通锦囊牌时，你令至你距离为2以内的其他角色不能响应此牌。"..
  "每当你对其他角色造成伤害后，令其非锁定技失效，直到任意其他角色的回合开始。",
  ["joy__jiaozi"] = "骄恣",
  [":joy__jiaozi"] = "锁定技，当你造成伤害时，若你的手牌为全场最多，则此伤害+1。",
  ["@@joyfuji"] = "伏骑",
}


return extension
