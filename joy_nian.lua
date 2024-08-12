local extension = Package("joy_nian")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_nian"] = "欢乐-念",
}

local U = require "packages/utility/utility"

local lvbu = General(extension, "joy_nian__lvbu", "qun", 5)
lvbu.hidden = true
lvbu.total_hidden = true

--[[
  踏阵出现逻辑（推测）：
  尽量且至多3名存活其他角色，若没有合法角色，结束踏阵
  令X=3-目标人数，当X>0时，会出现0-X个空格
  2-5张【杀】
  剩下随机用【酒】、【马】填充
]]

local tazhen = fk.CreateTriggerSkill{
  name = "joy__tazhen",
  anim_type = "offensive",
  frequency = Skill.Compulsory,
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) --and target == player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local victims, record = {}, {}
    -- prepare tazhen content
    local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
    if #targets > 0 then
      local list = table.random(targets, 3)
      local blank_num = 3 - #list
      if blank_num > 0 then
        blank_num = math.random(blank_num + 1) - 1
        for i = 1, blank_num do
          table.insert(list, "blank")
        end
      end
      for i = 1, math.random(2, 5) do
        table.insert(list, "slash")
      end
      for i = #list, 8 do
        table.insert(list, table.random({"analeptic", "horse"}))
      end
      table.shuffle(list)
      local result = room:askForCustomDialog(
        player, self.name,
        "packages/joym/qml/TazhenBox.qml",
        { list, math.max(0, player.hp) + 1 }
      )
      -- check tazhen rewards
      if result ~= "" then
        result = json.decode(result)
        local choices = table.map(result, function(i) return i + 1 end)
        if table.contains(choices, 5) then
          table.insert(record, "main")
        end
        for i, v in ipairs(choices) do
          local next, nnext = choices[i+1], choices[i+2]
          if nnext == nil then break end
          if math.abs(v - next) == 1 and (v - next) == (next - nnext) then
            table.insert(record, "line")
            break
          end
        end
        for i, v in ipairs(choices) do
          local next, nnext = choices[i+1], choices[i+2]
          if nnext == nil then break end
          if math.abs(v - next) == 3 and (v - next) == (next - nnext) then
            table.insert(record, "row")
            break
          end
        end
        local atk, buff = 0, 0
        for _, index in ipairs(choices) do
          local dat = list[index]
          if dat == "slash" then
            atk = atk + 1
          elseif dat == "analeptic" then
            buff = buff + 2
          elseif type(dat) == "number" then
            local hp = room:getPlayerById(dat).hp
            if buff + atk >= hp then
              table.insert(victims, dat)
            end
            buff = 0
          end
        end
      end
    end
    room:sendLog{ type = "#JoyTazhenResult", from = player.id, arg = #victims > 0 and "success" or "fail", toast = true }
    if #victims == 0 then return false end
    local slash = room:getCardsFromPileByRule("slash")
    if #slash > 0 then
      room:moveCards({
        ids = slash,
        to = player.id,
        toArea = Player.Hand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
    if player.dead then return end
    if not player:hasSkill("wushuang", true) then
      room:setPlayerMark(player,self.name,1)
      room:handleAddLoseSkills(player, "wushuang")
      if player.dead then return end
    end
    room:sortPlayersByAction(victims)
    room:doIndicate(player.id, victims)
    victims = table.map(victims, Util.Id2PlayerMapper)
    if not table.contains(record, "main") then
      local mark = U.getMark(player, "joy__tazhen_target")
      for _, p in ipairs(victims) do
        if not p.dead and table.insertIfNeed(mark, p.id) then
          room:addPlayerMark(p, "@@joy__tazhen")
        end
      end
      room:setPlayerMark(player, "joy__tazhen_target", mark)
    end
    if not table.contains(record, "row")  then
      for _, p in ipairs(victims) do
        if player.dead then break end
        if not p.dead and not p:isNude() then
          local cards = room:askForCard(p, 1, 1, true, self.name, false, ".", "#joy__tazhen-give:"..player.id)
          room:moveCardTo(cards, Player.Hand, player, fk.ReasonGive, self.name, nil, false, p.id)
        end
      end
    end
    if not table.contains(record, "line") then
      for _, p in ipairs(victims) do
        if player.dead then break end
        if not p.dead then
          room:useVirtualCard("slash", nil, player, p, self.name, true)
        end
      end
    end
  end,

  refresh_events = {fk.TurnStart, fk.BuryVictim},
  can_refresh = function (self, event, target, player, data)
    return target == player and (player:getMark(self.name) ~= 0 or player:getMark("joy__tazhen_target") ~= 0)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if player:getMark(self.name) > 0  then
      room:setPlayerMark(player, self.name, 0)
      room:handleAddLoseSkills(player, "-wushuang")
    end
    local mark = player:getMark("joy__tazhen_target")
    if mark ~= 0 then
      room:setPlayerMark(player, "joy__tazhen_target", 0)
      for _, pid in ipairs(mark) do
        local p = room:getPlayerById(pid)
        room:removePlayerMark(p, "@@joy__tazhen")
      end
    end
  end,
}

local tazhen_prohibit = fk.CreateProhibitSkill{
  name = "#joy__tazhen_prohibit",
  is_prohibited = function(self, from, to, card)
    return from and to and table.contains(U.getMark(to, "joy__tazhen_target") ,from.id) and card and card.trueName == "slash"
  end,
}
tazhen:addRelatedSkill(tazhen_prohibit)

lvbu:addSkill(tazhen)
lvbu:addRelatedSkill("wushuang")

Fk:loadTranslationTable{
  ["joy_nian__lvbu"] = "念吕布",

  ["joy__tazhen"] = "踏阵",
  [":joy__tazhen"] = "锁定技，回合开始时，你进行一次“踏阵”，成功后摸一张【杀】并获得技能〖无双〗直到你的下回合开始；"..
  "若你本次“踏阵”过程未路经："..
  "<br>①一整列，令“踏阵”中击败的角色依次交给你一张牌；"..
  "<br>②一整行，依次视为对“踏阵”中击败的角色使用一张不计次数的【杀】。"..
  "<br>③中心格，直到你的下回合开始前，“踏阵”中击败的角色无法对你使用【杀】。"..
  "<br><font color='grey'><b>踏阵</b>：规划路径并行进于九宫格中，提升伤害并尽可能击败拦路的敌人，踏阵可行进步数等同于当前体力值+1。击败阵中任意一名武将则视为踏阵成功，否则为踏阵失败。</font>",

  ["joy__tazhen_prompt1"] = "未路经一整列",
  [":joy__tazhen_prompt1"] = "交给你一张牌",
  ["joy__tazhen_prompt2"] = "未路经一整行",
  [":joy__tazhen_prompt2"] = "视为使用【杀】",
  ["joy__tazhen_prompt3"] = "未路经中心路",
  [":joy__tazhen_prompt3"] = "不能对你用【杀】",
  ["#JoyTazhenResult"] = "%from 踏阵 %arg",
  ["#joy__tazhen-give"] = "踏阵：请交给 %src 一张牌",
  ["Rest Step"] = "剩余步数",
  ["ATK Num"] = "攻击力",
  ["@@joy__tazhen"] = "踏阵",
}










return extension