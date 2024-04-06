
module ntl_events::events{
    use sui::package;
    use sui::display;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext,sender};
    use std::string::{Self,utf8, String};
    use sui::clock::{Self, Clock};
    use sui::event::{emit};
    use sui::url::{Self,Url};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use std::option::{Self,Option};
    use sui::address;
    use sui::coin::{Self,Coin};
    use sui::transfer::{transfer, public_transfer, share_object};
    use sui::dynamic_object_field as dof;
    use std::vector;
    use sui::object_table::{Self, ObjectTable};
    use ntl_events::utils::{ withdraw_balance};
    
    const ERR_OPENING_DATE_FOR_SALE:u64 = 1;
    const ERR_CLOSING_DATE_FOR_SALE:u64 = 2;
    const ERR_START_DATE:u64 = 3;
    const ERR_END_DATE:u64 = 4;
    const ERR_EVENT_NOT_STARTED_FORSALE:u64 = 5;
    const ERR_EVENT_HAS_CLOSED_FOR_SALE:u64 = 6;
    const ERR_EVENT_NOT_START_FOR_CHECKIN:u64 = 7;
    const ERR_EVENT_HAS_ENDED:u64 = 8;
    const ERR_USER_HAS_REGISTERED_EVENT:u64 = 9;
    const ERR_NOT_ENGOUH_FUND:u64 = 10;
    const ERR_USER_HAS_CHECKED_IN:u64 = 11;
    const ERR_USER_HAS_NOT_REGISTERED:u64 = 12;
    const ERR_ONLY_USER_REGISTERED:u64 = 13;
    const EROR_NOT_AUTHORIZED:u64 = 14;


    const EVENT_TYPE_FREE:u64 =100;
    const EVENT_TYPE_PAID:u64 =101;

    const EVENT_STATUS_REGISTED:u64 =200;
    const EVENT_STATUS_ATTENDED:u64 =201;
    

    //Event
    struct EventCreated has copy, drop {
        id: ID,
    }
    struct EventRegistered has copy, drop {
        id: ID,
        user: address,
    }
    struct EventCheckedIn has copy, drop {
        id: ID,
        user: address,
    }
    struct PostCreated has copy, drop {
      id: ID,
      creator: address,
    }

    struct EVENTS has drop{}

    struct AdminCap has key{
        id:UID,
        admin:address,
    }

    struct EventOrganizerCap has key, store {
        id: UID,
        event_id: ID,
    }
    
    struct EventsHub has key{
        id:UID,

    }

    struct EventNFT has key{
       id:UID,
       event_id:ID,
    }

    struct Attendee has key,store{
        id:UID,
        user_address:address,
        status:u64,
    }

    struct Post has key,store{
        id:UID,
        user_id:address,
        content:String,
        media:vector<Url>,
    }

    struct EventInfo has key {
        id:UID,
        opening_day_for_sale:u64,
        closing_day_for_sale:u64,
        start_date:u64,
        end_date:u64,
        type_event:u64, 
        price:u64,
        balance:Balance<SUI>, 
        attendees:ObjectTable<address,Attendee>,
        posts:ObjectTable<ID,Post>
    } 
    struct EventListed has key,store{
        id:UID,
        event_id:ID,
        name:String,
        description:String,
        image:Url,
        opening_day_for_sale:u64,
        closing_day_for_sale:u64,
        start_date:u64,
        end_date:u64,
        location:String,
        type_event:u64,
        price:u64,
    }
    fun init(otw: EVENTS, ctx: &mut TxContext) {
        let creator = sender(ctx);
        let adminCap = AdminCap{ 
            id: object::new(ctx),
            admin:creator,
         };
         let eventsHub = EventsHub{
            id: object::new(ctx),
         };

        let eventsHub_keys = vector[
          utf8(b"Name"),
          utf8(b"Description"),
          utf8(b"Image Uri"),
          utf8(b"Link"),
        ];
    
        let eventsHub_values = vector[
          utf8(b"SUIEVENTS"),
          utf8(b"The app(PWA) for listing Sui or Sui-related events (ex. Luma or eventbrite) utilizing dynamic NFTs"),
          utf8(b"https://pbs.twimg.com/card_img/1766108386188464128/1lRmJNor?format=jpg&name=medium"),
          utf8(b"https://sui.io/"),
        ];

        let publisher = package::claim(otw, ctx);
        let display = display::new_with_fields<EventsHub>(&publisher, eventsHub_keys, eventsHub_values, ctx);
   
        display::update_version(&mut display);

        public_transfer(publisher, creator);
        public_transfer(display, creator);
        transfer(adminCap, creator);
        share_object(eventsHub);
    }

   public entry fun create_event (
     events_hub:&mut EventsHub,
     name:String,
     description:String,
     image:String,
     opening_day_for_sale:u64,
     closing_day_for_sale:u64,
     start_date:u64,
     end_date:u64,
     location:String,
     type_event:u64,
     price:u64,
     clock:&Clock,
     ctx:&mut TxContext
     ){
    let creator = sender(ctx);
    let now = clock::timestamp_ms(clock);
    assert!(opening_day_for_sale >= now, ERR_OPENING_DATE_FOR_SALE);
    assert!(closing_day_for_sale > opening_day_for_sale, ERR_CLOSING_DATE_FOR_SALE);
    assert!(start_date >= closing_day_for_sale, ERR_START_DATE);
    assert!(end_date > start_date, ERR_END_DATE);
    let event_id = object::new(ctx);
    let id_copy = object::uid_to_inner(&event_id);
    let event = EventInfo{
      id: event_id,
      opening_day_for_sale: opening_day_for_sale,
      closing_day_for_sale: closing_day_for_sale,
      start_date: start_date,
      end_date: end_date,
      type_event: type_event,
      price: price,
      balance: balance::zero<SUI>(),
      attendees:object_table::new<address,Attendee>(ctx),
      posts: object_table::new<ID,Post>(ctx),
    };
    let organizer_cap = EventOrganizerCap{
        id: object::new(ctx),
        event_id: object::uid_to_inner(&event.id),
     };
      emit(EventCreated {
      id: object::uid_to_inner(&event.id)
      });
      share_object(event);
      dof::add(&mut events_hub.id, id_copy, EventListed{
        id: object::new(ctx),
        event_id: id_copy,
        name: name,
        description: description,
        image: url::new_unsafe(string::to_ascii(image)),
        opening_day_for_sale: opening_day_for_sale,
        closing_day_for_sale: closing_day_for_sale,
        start_date: start_date,
        end_date: end_date,
        location: location,
        type_event: type_event,
        price: price,
      });
      public_transfer(organizer_cap, creator);
    }

    public entry fun register_event(
        event_mut: &mut EventInfo,
        clock: &Clock,
        amount:Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let user = sender(ctx);
        let now = clock::timestamp_ms(clock);
        assert!(now >= event_mut.opening_day_for_sale,ERR_EVENT_NOT_STARTED_FORSALE );
        assert!(now < event_mut.closing_day_for_sale,ERR_EVENT_HAS_CLOSED_FOR_SALE);
        assert!(!checkUserRegisteredEvent(event_mut,user),ERR_USER_HAS_REGISTERED_EVENT);
        let value = coin::value(&amount);
        assert!(value >= event_mut.price,ERR_NOT_ENGOUH_FUND);
        let balance_input = coin::into_balance(amount);
        balance::join(&mut event_mut.balance, balance_input);
        let eventNft = EventNFT{
          id: object::new(ctx),
          event_id:object::uid_to_inner(&event_mut.id),
        };
        transfer(eventNft,user);
        emit(EventRegistered {
          id: object::uid_to_inner(&event_mut.id),
           user:user
          });
        object_table::add(&mut event_mut.attendees, user, Attendee{
          id: object::new(ctx),
          user_address: user,
          status: EVENT_STATUS_REGISTED,
        });   
          
    }

    public entry fun widthdraw<T>(
      event:&mut EventInfo,
      event_cap:&EventOrganizerCap,
      ctx: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      let balance = &mut event.balance;
      withdraw_balance(balance, ctx);
    }
    
    public entry fun checkin_event(
        event_mut: &mut EventInfo,
        clock:&Clock,
        ctx: &mut TxContext,
    ) { 
        let now = clock::timestamp_ms(clock);
        let user = sender(ctx);
        assert!(now >= event_mut.start_date,ERR_EVENT_NOT_START_FOR_CHECKIN);
        assert!(now < event_mut.end_date,ERR_EVENT_HAS_ENDED);
        assert!(checkUserRegisteredEvent(event_mut,user),ERR_USER_HAS_NOT_REGISTERED);
        let attendee = object_table::borrow_mut<address,Attendee>(&mut event_mut.attendees, user);
        assert!(attendee.status != EVENT_STATUS_ATTENDED,ERR_USER_HAS_CHECKED_IN);
        attendee.status = EVENT_STATUS_ATTENDED;
        emit(EventCheckedIn {
          id: object::uid_to_inner(&event_mut.id),
          user:user
        });
  }   
   public entry fun post(
    event_mut: &mut EventInfo,
    contents: String,
    media:vector<String>,
    ctx: &mut TxContext,
   ){
    let user = sender(ctx);
    assert!(checkUserRegisteredEvent(event_mut,user),ERR_ONLY_USER_REGISTERED);
    let length = vector::length(&media);
    let i = 0;
    let medias = vector::empty<Url>();
    while(i < length) {
    //  let url = url::new_unsafe_from_bytes(vector::pop_back(&mut media));
    let url =url::new_unsafe(string::to_ascii(vector::pop_back(&mut media)));
      vector::push_back(&mut medias, url);
      i = i + 1;
    };
    let post = Post{
      id: object::new(ctx),
      user_id: user,
      content:contents,
      media: medias,
    }; 
     emit(PostCreated {
      id: object::uid_to_inner(&post.id),
      creator: user,
      });
    object_table::add(&mut event_mut.posts, object::id(&post), post);
    
   }

   //Update event_related_fields
   
   public fun update_event_name (
    event_cap:&EventOrganizerCap,
    events_hub:&mut EventsHub,
    event: &EventInfo,
    name:String,
    _: &mut TxContext,
   ){
    check_event_admin(event_cap, event);
    let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
    event_listed.name = name;
   }

    public fun update_event_description (
      event_cap:&EventOrganizerCap,
      events_hub:&mut EventsHub,
      event: &EventInfo,
      description:String,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
      event_listed.description = description;
    }

    public fun update_event_image (
      event_cap:&EventOrganizerCap,
      events_hub:&mut EventsHub,
      event: &EventInfo,
      image:vector<u8>,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
      event_listed.image = url::new_unsafe_from_bytes(image);
    }

    public fun update_event_location (
      event_cap:&EventOrganizerCap,
      events_hub:&mut EventsHub,
      event: &EventInfo,
      location:String,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
      event_listed.location = location;
    }

    public fun update_event_price (
      events_hub:&mut EventsHub,
      event_cap:&EventOrganizerCap,
      event: &mut EventInfo,
      price:u64,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
       event.price = price;
       let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
        event_listed.price = price;
    }
    
    public fun update_event_opening_day_for_sale (
      event_cap:&EventOrganizerCap,
      events_hub:&mut EventsHub,
      event: &mut EventInfo,
      opening_day_for_sale:u64,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      event.opening_day_for_sale = opening_day_for_sale;
      let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
      event_listed.opening_day_for_sale = opening_day_for_sale;
    }
    
    public fun update_event_closing_day_for_sale (
      event_cap:&EventOrganizerCap,
      events_hub:&mut EventsHub,
      event: &mut EventInfo,
      closing_day_for_sale:u64,
      _: &mut TxContext,
    ){
      check_event_admin(event_cap, event);
      event.closing_day_for_sale = closing_day_for_sale;
      let event_listed = dof::borrow_mut<ID,EventListed>(&mut events_hub.id, object::uid_to_inner(&event.id));
      event_listed.closing_day_for_sale = closing_day_for_sale;
    }
   // ======== View functions: EVENT =========
   public fun get_event(hub: &EventsHub,event:&EventInfo): &EventListed {
     dof::borrow<ID,EventListed>(&hub.id, object::uid_to_inner(&event.id))
   }   
   public fun get_event_name(hub: &EventsHub,event:&EventInfo): String {
     get_event(hub,event).name
   }
    public fun get_event_description(hub: &EventsHub,event:&EventInfo): String {
      get_event(hub,event).description
    }
    public fun get_event_image(hub: &EventsHub,event:&EventInfo): Url {
      get_event(hub,event).image
    }
    public fun get_event_location(hub: &EventsHub,event:&EventInfo): String {
      get_event(hub,event).location
    }
    public fun get_event_price(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).price
    }
    public fun get_event_opening_day_for_sale(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).opening_day_for_sale
    }
    public fun get_event_closing_day_for_sale(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).closing_day_for_sale
    }
    public fun get_event_start_date(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).start_date
    }
    public fun get_event_end_date(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).end_date
    }
    public fun get_event_type(hub: &EventsHub,event:&EventInfo): u64 {
      get_event(hub,event).type_event
    }


  // ======== View functions: POST =========
   public fun get_posts(event:&EventInfo,post_id:ID): &Post {
      object_table::borrow<ID,Post>(&event.posts, post_id)
   }
   public fun get_post_media(event:&EventInfo,post_id:ID): vector<Url> {
      get_posts(event,post_id).media
   }
   public fun get_post_creator(event:&EventInfo,post_id:ID): address {
      get_posts(event,post_id).user_id
   }
    public fun get_post_content(event:&EventInfo,post_id:ID): String {
        get_posts(event,post_id).content
    }

   // ======== View functions: ATTENDEE ========= 
   public fun get_attendee(event:&EventInfo,user:address): &Attendee {
    object_table::borrow<address,Attendee>(&event.attendees, user)
  }
  
  public fun get_attendee_status(event:&EventInfo,user:address): u64 {
    get_attendee(event,user).status
  }

  // function to check 
  fun checkUserRegisteredEvent(
    event_mut: &EventInfo,
    user: address): bool 
    { object_table::contains(&event_mut.attendees, user)}

fun check_event_admin(admin_cap: &EventOrganizerCap, event: &EventInfo) {
  assert!(admin_cap.event_id == object::id(event),EROR_NOT_AUTHORIZED )
}
//===========TEST FUNCTION===========  
#[test_only]
public fun test_new_event_hub(ctx: &mut TxContext) {
    share_object(EventsHub {
        id: object::new(ctx),
    })
}

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
  init(EVENTS {}, ctx)
}
}  