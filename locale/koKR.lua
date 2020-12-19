﻿if GetLocale() == "koKR" then
	BINDING_HEADER_GOGOHEADER = "GoGoMount"
	BINDING_NAME_GOGOBINDING = "타기/내리기"
	BINDING_NAME_GOGOBINDING2 = "타기/내리기 (나는 탈것 제외)"
	BINDING_NAME_GOGOBINDING3 = "2인승 탈것 타기/내리기"
	GoGo_Variables.Localize = {
	Skill = {
		Engineering = "기계공학",
		Riding = "탈것 타기",
		Tailoring = "재봉술",
	},
	String = {
		AutoExcludeFlyingMountsInNoFlyAreas = "Automatically exclude flying mounts in \"no fly\" areas", -- Requires localization
		AutoExcludeFlyingMountsInNoFlyAreas_Long = "With this option enabled, GoGoMount will automatically remove all mounts that can fly from the random mount selection when it believes you can't actually fly.  This is almost the same as using key binding #2 for GoGoMount.  This will be useful while leveling up, in battle grounds, etc.  Note that if your list of favorite mounts contains all mounts that can fly and you trying mounting in a battle ground with this option enabled, you may not mount at all.", -- Requires localization
		AutomaticallyRemoveBuffs = "자동으로 탈것 버프 제거",
		AutoStartCrusaderAura = "성전사의 오라 자동 시전", -- Needs review
		AutoStartCrusaderAura_Long = "GoGoMount로 탈것 탑승시 자동으로 성전사의 오라를 시전합니다.", -- Needs review
		Clear = "제거",
		ClearGlobalFavoriteMounts = "즐겨찾기 탈것 제거",
		CurrentZone = "현재 지역", -- Needs review
		CurrentZoneDescription = "Mounts flagged here as zone favorites will be the only mounts GoGoMount will use in this zone.  All other mounts and shape forms will be ignored.  Clearing this list will allow GoGoMount to use all mounts (or global favorites if set).", -- Requires localization
		CurrentZoneExclusions = "현재 지역 제외", -- Needs review
		CurrentZoneFavorites = "현재 지역 즐겨찾기",
		DisableFlyingFromWater = "물에서 나는 탈것 비활성화", -- Needs review
		DisableInCombat = "전투 상태시 GoGoMount 버튼 비활성화", -- Needs review
		DisableInCombat_Long = "이 옵션은 전투 중에 GoGoMount 버튼을 비활성화합니다. 곰폼의 방어전담 드루이드가 실수로 GoGoMount 버튼을 누르는것을 방지합니다. 전투에 들어가기 전에 활성화 또는 비활성화합니다.", -- Needs review
		DisableUnknownMountNotices = "알 수 없는 탈것 안내 비활성화",
		DisableUpdateNotices = "업데이트 안내 비활성화",
		DruidFlightPreference = "항상 움직일때 비행 형태의 변신 사용", -- Needs review
		DruidOptions = "드루이드 옵션",
		DruidSingleClick = "변신 상태에서 다른 변신 형태로 한번의 클릭으로 변경", -- Needs review
		EnableAutoDismount = "자동 탈것 내리기 활성화",
		ExtraPassengerMounts = "Extra Passenger Mounts", -- Requires localization
		ExtraPassengerMountsDescription = "This list of passenger mounts is used to add passenger mounts to the random selection only when the Passenger Mount button is pressed.  This will allow you to set preferred mount lists excluding passenger mounts but still have them available when using the Passenger Mount button.  These mounts will not be used if they are marked as excluded mounts globally or for the current zone you are in.", -- Requires localization
		Favorites = "즐겨찾기",
		GlobalExclusions = "공통 제외", -- Needs review
		GlobalExclusionsDescription = "탈것을 항상 무시합니다. 여기에 선택된 탈것을 즐겨찾기로 설정하더라도 사용할 수 없습니다.", -- Needs review
		GlobalFavorites = "일반적인 즐겨찾기",
		GlobalPreferences = "일반 설정",
		GlobalZoneDescription = "Preferred mounts defined here will only take effect if there are no zone specific mount favorites set for the current zone you are in.", -- Requires localization
		HunterOptions = "사냥꾼 옵션",
		NewVersionFound = "GoGoMount의 새로운 버전을 사용할 수 있습니다.",
		NightFaeOptions = "Night Fae Options", -- Requires localization
		NightFaeOptions = "Single click mount from Soulshape instead of dismounting", -- Requires localization
		NoShapeInRandom = "탈것이나 변신 폼 무작위로 사용 안함",
		PaladinOptions = "성기사 옵션", -- Needs review
		RemoveBuffs = "탈것을 방해하는 버프 제거",
		RemoveBuffs_Long = "GoGoMount will attempt to remove buffs and shapeforms that come from spells and items that prevent mounting.  This only works for known buffs and in some cases require 2 clicks of your GoGoMount button to mount.", -- Requires localization
		ShamanOptions = "Shaman Options", -- Requires localization
		ShamanSingleClick = "Single click mount from Ghost Wolf Form instead of dismounting", -- Requires localization
		UnknownMountFound = "알 수 없는 탈것이 당신의 목록에서 발견되었습니다. 이것을 GoGoMount의 다음 버전에 추가될 수 있도록 알리십시오.",
		UseAspectOfThePackInstead = "치타의 상 대신 치타 무리의 상 사용",
		UseAspectOfThePackInstead_Long = "When enabled, GoGoMount will cast Aspect of the Pack instead of Aspect of the Cheetah.  Local zone or global settings override this setting.  If this is set to use Aspect of the Pack and you have Aspect of the Cheetah as a zone favorite, Aspect of the Cheetah will be used.", -- Requires localization
		ZoneExclusionsDescription = "Zone specific exclusions work the same as global exclusions but specific to this zone.  Any mount marked below as an exclusion for the zone you're currently in will never be summoned.", -- Requires localization
	},
	Talent = {
		AncestralSwiftness = "고대의 신속함",
		FeralSwiftness = "야생의 기민함",
	},
	Zone = {
		AbyssalDepths = "심연의 나락",
		AmaniMountains = "아마니 산맥", -- Needs review
		AQ40 = "안퀴라즈",
		AzuremystIsle = "하늘안개 섬",
		BloodmystIsle = "핏빛안개 섬",
		CrumblingDepths = "무너지는 심연",
		Dalaran = "달라란",
		DarkbreakCove = "어둠돌파 만",
		Deepholm = "심원의 영지",
		DireMaul = "혈투의 전장",
		EversongWoods = "영원노래 숲",
		Ghostlands = "유령의 땅",
		Icecrown = "얼음왕관",
		Ironforge = "아이언포지",
		IsleOfQuelDanas = "쿠엘다나스 섬",
		KrasusLanding = "크라서스 착륙장",
		LegionsRest = "군단의 안식처",
		Lghorek = "고레크",
		Nespirah = "네스피라",
		ShimmeringExpanse = "흐린빛 벌판",
		SholazarBasin = "숄라자르 분지",
		SilvermoonCity = "실버문",
		SilverTideHollow = "은빛 너울 동굴",
		TempleOfBethekk = "베데크 신전", -- Needs review
		TempleOfEarth = "대지의 신전",
		TenebrousCavern = "음침한 동굴",
		ThalassianPass = "탈라시안 고개", -- Needs review
		ThalassianRange = "탈라시안 산줄기", -- Needs review
		TheCerebrillum = "두뇌실",
		TheExodar = "엑소다르",
		TheFrozenSea = "얼어붙은 바다",
		TheOculus = "마력의 눈",
		TheStormPeaks = "폭풍우 봉우리",
		TheTempleOfAtalHakkar = "아탈학카르 신전",
		TheUnderbelly = "마법의 뒤안길",
		TheVioletCitadel = "보랏빛 성채",
		TheVortexPinnacle = "소용돌이 누각",
		TolBarad = "톨 바라드",
		TolBaradPeninsula = "톨 바라드 반도",
		TwistingNether = "뒤틀린 황천",
		Vashjir = "바쉬르",
		Wintergrasp = "겨울손아귀 호수",
	}
}
end --if