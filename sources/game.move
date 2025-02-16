module clothing_marketplace::store {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::transfer_policy::{Self as tp};
    use sui::package::{Self, Publisher};
    use sui::transfer;

    use std::string::{String};
    use std::collections::HashMap;
    
    struct Apparel has key, store {
        id: UID,
        name: String,
        description: String,
        price: u64,
        stock: u64,
        size: String,
        color: String,
    }
    
    struct Order has key, store {
        id: UID,
        items: HashMap<UID, u64>, // Map of apparel item IDs to quantities
        total_amount: u64,
        status: String, // Pending, Shipped, Delivered, Cancelled, etc.
    }

    struct ShoppingCart has key, store {
        id: UID,
        items: HashMap<UID, u64>, // Map of apparel item IDs to quantities
        total_amount: u64,
    }
    
    struct CustomerAccount has key, store {
        id: UID,
        username: String,
        email: String,
        password: String,
        orders: Vec<UID>, // List of order IDs
        shopping_cart: UID, // Shopping cart ID
    }
    
    /// Publisher capability object
    struct ApparelPublisher has key { id: UID, publisher: Publisher }
    struct OrderPublisher has key { id: UID, publisher: Publisher }
    struct ShoppingCartPublisher has key { id: UID, publisher: Publisher }
    struct CustomerAccountPublisher has key { id: UID, publisher: Publisher }

    // one time witness 
    struct STORE has drop {}

    // Only owner of this module can access it.
    struct AdminCap has key {
        id: UID,
    }

    // =================== Initializer ===================
    fun init(otw:STORE, ctx: &mut TxContext) {
        // Define publishers
        let apparel_publisher = package::claim<STORE>(otw, ctx);
        let order_publisher = package::claim<STORE>(otw, ctx);
        let shopping_cart_publisher = package::claim<STORE>(otw, ctx);
        let customer_account_publisher = package::claim<STORE>(otw, ctx);
        
        // Share publishers
        transfer::share_object(ApparelPublisher {
            id: object::new(ctx),
            publisher: apparel_publisher,
        });
        transfer::share_object(OrderPublisher {
            id: object::new(ctx),
            publisher: order_publisher,
        });
        transfer::share_object(ShoppingCartPublisher {
            id: object::new(ctx),
            publisher: shopping_cart_publisher,
        });
        transfer::share_object(CustomerAccountPublisher {
            id: object::new(ctx),
            publisher: customer_account_publisher,
        });

        // Transfer the admin cap
        transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    /// Users can create new kiosk for marketplace 
    public fun new(ctx: &mut TxContext) : KioskOwnerCap {
        let (kiosk, kiosk_cap) = kiosk::new(ctx);
        // Share the kiosk
        transfer::public_share_object(kiosk);
        kiosk_cap
    }
    
    // create any transferpolicy for rules 
    public fun new_policy(publish: &ApparelPublisher, ctx: &mut TxContext ) {
        // Set the publisher
        let publisher = get_apparel_publisher(publish);
        // Create an transfer_policy and tp_cap
        let (transfer_policy, tp_cap) = tp::new<Apparel>(publisher, ctx);
        // Transfer the objects 
        transfer::public_transfer(tp_cap, tx_context::sender(ctx));
        transfer::public_share_object(transfer_policy);
    }
    
    // Function to add a new apparel item to the store
    public fun new_apparel(name: String, description: String, price: u64, stock: u64, size: String, color: String, ctx: &mut TxContext): Apparel {
        Apparel {
            id: object::new(ctx),
            name,
            description,
            price,
            stock,
            size,
            color,
        }
    }

    // Function to get all apparel items in the store
    public fun get_apparel(store: &Apparel): &Apparel {
        store
    }

    // Function to delete an apparel item from the store
    public fun delete_apparel(apparel: Apparel) {
        let Apparel { id, name: _, description: _, price: _, stock: _, size: _, color: _ } = apparel;
        object::delete(id);
    }

    // Function to update the stock of an apparel item
    public fun update_stock(apparel: &mut Apparel, new_stock: u64) {
        apparel.stock = new_stock;
    }
    
    public fun update_name(apparel: &mut Apparel, name_: String) {
        apparel.name = name_;
    }
    
    public fun update_description(apparel: &mut Apparel, description: String) {
        apparel.description = description;
    }
    
    public fun update_price(apparel: &mut Apparel, price: u64) {
        apparel.price = price;
    }
    
    public fun update_size(apparel: &mut Apparel, size: String) {
        apparel.size = size;
    }
    
    public fun update_color(apparel: &mut Apparel, color: String) {
        apparel.color = color;
    }

    // Function to add a new order
    public fun new_order(items: HashMap<UID, u64>, total_amount: u64, status: String, ctx: &mut TxContext) -> Order {
        Order {
            id: object::new(ctx),
            items,
            total_amount,
            status,
        }
    }

    // Function to get an order by ID
    public fun get_order(order_id: UID) -> Option<Order> {
        object::get(order_id)
    }

    // Function to add a new shopping cart
    public fun new_shopping_cart(items: HashMap<UID, u64>, total_amount: u64, ctx: &mut TxContext) -> ShoppingCart {
        ShoppingCart {
            id: object::new(ctx),
            items,
            total_amount,
        }
    }

    // Function to get a shopping cart by ID
    public fun get_shopping_cart(cart_id: UID) -> Option<ShoppingCart> {
        object::get(cart_id)
    }

    // Function to add a new customer account
    public fun new_customer_account(username: String, email: String, password: String, ctx: &mut TxContext) -> CustomerAccount {
        let shopping_cart = new_shopping_cart(HashMap::new(), 0, ctx).id;
        CustomerAccount {
            id: object::new(ctx),
            username,
            email,
            password,
            orders: Vec::new(),
            shopping_cart,
        }
    }

    // Function to get a customer account by ID
    public fun get_customer_account(account_id: UID) -> Option<CustomerAccount> {
        object::get(account_id)
    }

    // Function to add an order to a customer's account
    public fun add_order_to_account(account: &mut CustomerAccount, order_id: UID) {
        account.orders.push(order_id);
    }

    // =================== Helper Functions ===================

    // Return the apparel publisher
    fun get_apparel_publisher(shared: &ApparelPublisher) -> &Publisher {
        &shared.publisher
    }

    // Return the order publisher
    fun get_order_publisher(shared: &OrderPublisher) -> &Publisher {
        &shared.publisher
    }

    // Return the shopping cart publisher
    fun get_shopping_cart_publisher(shared: &ShoppingCartPublisher) -> &Publisher {
        &shared.publisher
    }

    // Return the customer account publisher
    fun get_customer_account_publisher(shared: &CustomerAccountPublisher) -> &Publisher {
        &shared.publisher
    }

    #[test_only]
    // Call the init function
    public fun test_init(ctx: &mut TxContext) {
        init(STORE {}, ctx);
    }
}
