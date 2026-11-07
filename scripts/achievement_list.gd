class_name AchievementList
extends RefCounted
## 업적 목록. 이름은 영어, 설명은 한국어(korean_font.tres). 판정은 achievements.gd에서 한다.
## hidden: 달성 전에는 목록에 이름과 설명을 숨긴다.

const ITEMS: Array[Dictionary] = [
    # 엔딩
    {'id': 'perfect_alibi', 'name': 'Perfect Alibi', 'desc': '레벨 1을 클리어했다.'},
    {'id': 'party_survivor', 'name': 'Party Survivor', 'desc': '레벨 2를 클리어했다.'},
    {'id': 'halfway_home', 'name': 'Halfway Home', 'desc': '레벨 5를 클리어했다.'},
    {'id': 'hallway_hero', 'name': 'Hallway Hero', 'desc': '레벨 7을 클리어했다.'},
    {'id': 'last_call', 'name': 'Last Call', 'desc': '레벨 9를 클리어했다.'},
    {'id': 'busted', 'name': 'Busted', 'desc': '주변 사람에게 휴대폰 화면을 들켰다.'},
    {'id': 'left_on_read', 'name': 'Left on Read', 'desc': '답장이 늦어 차단당했다.'},
    {'id': 'all_eyes_on_you', 'name': 'All Eyes on You', 'desc': '모두가 나를 둘러쌌다. 히든 엔딩을 봤다.', 'hidden': true},
    {'id': 'seen_it_all', 'name': 'Seen It All', 'desc': '엔딩 4종을 모두 봤다.'},
    {'id': 'serial_offender', 'name': 'Serial Offender', 'desc': '들킴 엔딩을 10번 봤다.'},
    {'id': 'ghosted_again', 'name': 'Ghosted Again', 'desc': '차단 엔딩을 10번 봤다.'},
    {'id': 'down_to_the_wire', 'name': 'Down to the Wire', 'desc': '메시지가 9단계까지 쌓인 채로 레벨을 클리어했다.'},
    # 레벨 진행과 점수
    {'id': 'room_by_room', 'name': 'Room by Room', 'desc': '레벨 1~3을 모두 클리어했다.'},
    {'id': 'every_room_counts', 'name': 'Every Room Counts', 'desc': '레벨 4~6을 모두 클리어했다.'},
    {'id': 'the_long_night', 'name': 'The Long Night', 'desc': '레벨 7~9를 모두 클리어했다.'},
    {'id': 'full_party', 'name': 'Full Party', 'desc': '9개 레벨을 모두 클리어했다.'},
    {'id': 'new_best', 'name': 'New Best', 'desc': '최고 점수를 갱신했다.'},
    {'id': 'high_scorer', 'name': 'High Scorer', 'desc': '한 판에서 5,000점을 넘겼다.'},
    {'id': 'score_hunter', 'name': 'Score Hunter', 'desc': '한 판에서 12,000점을 넘겼다.'},
    {'id': 'record_collector', 'name': 'Record Collector', 'desc': '9개 레벨 모두 최고 점수 기록을 남겼다.'},
    {'id': 'bare_minimum', 'name': 'Bare Minimum', 'desc': '답장을 한 번도 하지 않고 레벨을 클리어했다.'},
    # 답장
    {'id': 'first_reply', 'name': 'First Reply', 'desc': '처음으로 답장을 보냈다.'},
    {'id': 'fast_thumbs', 'name': 'Fast Thumbs', 'desc': '첫 글자를 누르고 2초 안에 답장을 끝냈다.'},
    {'id': 'serial_texter', 'name': 'Serial Texter', 'desc': '답장을 모두 100번 보냈다.'},
    {'id': 'chatterbox', 'name': 'Chatterbox', 'desc': '답장을 모두 500번 보냈다.'},
    {'id': 'steady_hands', 'name': 'Steady Hands', 'desc': '틀린 글자 없이 레벨을 클리어했다.'},
    {'id': 'butterfingers', 'name': 'Butterfingers', 'desc': '한 판에서 글자를 10번 틀렸다.'},
    {'id': 'inbox_zero', 'name': 'Inbox Zero', 'desc': '메시지가 3단계를 넘지 않게 레벨을 클리어했다.'},
    {'id': 'quick_reply', 'name': 'Quick Reply', 'desc': '메시지가 오자마자 답장해 최고 점수를 받았다.'},
    {'id': 'full_sentence', 'name': 'Full Sentence', 'desc': '두 단어 이상인 문장으로 답장했다.'},
    {'id': 'novelist', 'name': 'Novelist', 'desc': '네 단어 문장으로 답장했다.'},
    {'id': 'big_words', 'name': 'Big Words', 'desc': '긴 단어가 들어간 답장을 10번 보냈다.'},
    {'id': 'crowded_keyboard', 'name': 'Crowded Keyboard', 'desc': '레벨 9에서 한 번도 틀리지 않고 답장했다.'},
    {'id': 'speed_reader', 'name': 'Speed Reader', 'desc': '한 판에서 답장을 10번 보냈다.'},
    {'id': 'shaky_hands', 'name': 'Shaky Hands', 'desc': '손이 가장 심하게 떨릴 때 답장을 끝냈다.'},
    {'id': 'last_second', 'name': 'Last Second', 'desc': '메시지가 9단계까지 쌓였을 때 답장했다.'},
    {'id': 'unbothered', 'name': 'Unbothered', 'desc': '휴대폰을 한 번도 켜지 않고 레벨을 클리어했다.'},
    {'id': 'phone_addict', 'name': 'Phone Addict', 'desc': '한 판에서 휴대폰을 30번 켰다.'},
    {'id': 'screen_time', 'name': 'Screen Time', 'desc': '휴대폰을 켠 채로 30초를 버텼다.'},
    # 여자친구 메시지
    {'id': 'left_her_on_seen', 'name': 'Left Her on Seen', 'desc': '여자친구 메시지를 눌러서 닫았다.'},
    {'id': 'do_not_disturb', 'name': 'Do Not Disturb', 'desc': '한 판에서 여자친구 메시지를 10번 닫았다.'},
    {'id': 'she_keeps_texting', 'name': 'She Keeps Texting', 'desc': '여자친구 메시지를 모두 50번 받았다.'},
    # 소품과 문
    {'id': 'party_planner', 'name': 'Party Planner', 'desc': '한 판에서 스피커, 조명, 플레이리스트를 모두 썼다.'},
    {'id': 'turn_it_up', 'name': 'Turn It Up', 'desc': '스피커를 처음 켰다.'},
    {'id': 'lights_camera', 'name': 'Lights, Camera', 'desc': '조명을 처음 켰다.'},
    {'id': 'dj_booth', 'name': 'DJ Booth', 'desc': '플레이리스트를 처음 틀었다.'},
    {'id': 'crowd_control', 'name': 'Crowd Control', 'desc': '플레이리스트로 사람 8명 이상을 한 번에 모았다.'},
    {'id': 'locked_in', 'name': 'Locked In', 'desc': '건너편 방에 5명 이상 있을 때 문을 닫았다.'},
    {'id': 'doorman', 'name': 'Doorman', 'desc': '한 판에서 문을 10번 여닫았다.'},
    {'id': 'uninvited', 'name': 'Uninvited', 'desc': '닫아 둔 문을 누군가 열고 들어왔다.'},
    {'id': 'prop_master', 'name': 'Prop Master', 'desc': '소품을 모두 100번 썼다.'},
    # 사람들
    {'id': 'social_butterfly', 'name': 'Social Butterfly', 'desc': '사람들에게 반응을 모두 50번 보냈다.'},
    {'id': 'good_vibes', 'name': 'Good Vibes', 'desc': '좋은 반응을 모두 100번 보냈다.'},
    {'id': 'hater', 'name': 'Hater', 'desc': '나쁜 반응을 모두 100번 보냈다.'},
    {'id': 'mixed_signals', 'name': 'Mixed Signals', 'desc': '한 사람에게 좋은 반응과 나쁜 반응을 모두 보냈다.'},
    {'id': 'first_impression', 'name': 'First Impression', 'desc': '한 판에서 서로 다른 사람 10명에게 반응을 보냈다.'},
    {'id': 'small_talk', 'name': 'Small Talk', 'desc': '따라오는 사람에게 말을 걸어 돌려보냈다.'},
    {'id': 'peacekeeper', 'name': 'Peacekeeper', 'desc': '따라오는 사람을 모두 10번 돌려보냈다.'},
    {'id': 'in_the_way', 'name': 'In the Way', 'desc': '길을 막다가 밀려났다.'},
    {'id': 'bouncer', 'name': 'Bouncer', 'desc': '한 판에서 서로 다른 사람 3명의 길을 막았다.'},
    {'id': 'shake_it_off', 'name': 'Shake It Off', 'desc': '한 판에서 5번 밀려났다.'},
    {'id': 'camper', 'name': 'Camper', 'desc': '한 방에 너무 오래 있어서 사람들이 몰려왔다.'},
    # 춤
    {'id': 'first_dance', 'name': 'First Dance', 'desc': '처음으로 함께 춤을 췄다.'},
    {'id': 'dance_machine', 'name': 'Dance Machine', 'desc': '한 판에서 춤을 3번 췄다.'},
    {'id': 'party_animal', 'name': 'Party Animal', 'desc': '춤을 모두 20번 췄다.'},
    {'id': 'slow_dancer', 'name': 'Slow Dancer', 'desc': '슬로우 댄스 타임에 답장을 보냈다.'},
    {'id': 'wallflower', 'name': 'Wallflower', 'desc': '슬로우 댄스 타임 내내 휴대폰을 켜지 않았다.'},
    # 무한 모드
    {'id': 'still_texting', 'name': 'Still Texting', 'desc': '무한 모드에서 5분을 버텼다.'},
    {'id': 'night_owl', 'name': 'Night Owl', 'desc': '무한 모드 레벨 3에 도달했다.'},
    {'id': 'endless_party', 'name': 'Endless Party', 'desc': '무한 모드 레벨 5에 도달했다.'},
    {'id': 'sunrise', 'name': 'Sunrise', 'desc': '무한 모드 레벨 10에 도달했다.'},
    {'id': 'one_time_deal', 'name': 'One-Time Deal', 'desc': '무한 모드 한 판에서 소품을 10개 썼다.'},
    {'id': 'endless_best', 'name': 'Endless Best', 'desc': '무한 모드 최고 점수를 갱신했다.'},
    # 숨은 재미
    {'id': 'take_the_l', 'name': 'Take the L', 'desc': '휴대폰에 LLL을 입력했다.', 'hidden': true},
    {'id': 'baji', 'name': 'BAJI!', 'desc': '휴대폰에 BAJI를 입력했다.', 'hidden': true},
    {'id': 'remix', 'name': 'Remix', 'desc': '한 판에서 LLL과 BAJI를 모두 입력했다.', 'hidden': true},
    {'id': 'meet_the_team', 'name': 'Meet the Team', 'desc': '홈 화면 휴대폰의 전원 버튼을 눌러 만든 사람들을 봤다.', 'hidden': true},
    {'id': 'ninety_nine_plus', 'name': '99+', 'desc': '홈 화면 알림을 99+까지 쌓았다.', 'hidden': true},
    {'id': 'read_the_manual', 'name': 'Read the Manual', 'desc': '게임 방법을 읽었다.'},
    {'id': 'volume_check', 'name': 'Volume Check', 'desc': '설정에서 음량을 바꿨다.'},
    {'id': 'rage_quit', 'name': 'Rage Quit', 'desc': '게임 도중 홈으로 나갔다.', 'hidden': true},
    {'id': 'try_again', 'name': 'Try Again', 'desc': '재도전을 10번 했다.'},
    # 수집
    {'id': 'completionist', 'name': 'Completionist', 'desc': '숨겨진 업적을 뺀 모든 업적을 달성했다.'},
    {'id': 'true_completionist', 'name': 'True Completionist', 'desc': '모든 업적을 달성했다.', 'hidden': true},
]


static func find(id: String) -> Dictionary:
    for item: Dictionary in ITEMS:
        if item['id'] == id:
            return item
    return {}


static func is_hidden(item: Dictionary) -> bool:
    return bool(item.get('hidden', false))
