#[derive(Copy, Drop, Serde, starknet::Store)]
struct Book {
    title: felt252,
    author: felt252,
    ISBN: felt252,
    price: u8,
    stock: u8,
}

#[starknet::interface]
pub trait IBook<TContractState> {
    fn add_book(
        ref self: TContractState,
        book_id: felt252,
        title: felt252,
        author: felt252,
        ISBN: felt252,
        price: u8,
        stock: u8,
    );
    fn update_book(ref self: TContractState, book_id: felt252, new_price: u8);
    fn remove_book(ref self: TContractState, book_id: felt252);
    fn get_book(self: @TContractState, book_id: felt252) -> Book;
    fn get_book_stock(self: @TContractState, book_id: felt252) -> u8;
    // fn check_stock(ref self: TContractState);

}

#[starknet::contract]
pub mod BookModule {
    use super::{Book, IBook};
    use core::starknet::{
        ContractAddress, get_caller_address,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess}
    };

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        BookAdded: BookAdded,
        BookUpdated: BookUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct BookAdded {
        title: felt252,
        author: felt252,
        ISBN: felt252,
        price: u8,
        stock: u8
    }

    #[derive(Drop, starknet::Event)]
    struct BookUpdated {
        title: felt252,
        book_id: felt252,
        price: u8,
    }

    #[storage]
    struct Storage {
        book: Map<felt252, Book>, // map book_id -> Book struct
        bookstore_manager: ContractAddress,
        book_count: Map<u8, Book>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, bookstore_manager: ContractAddress) {
        self.bookstore_manager.write(bookstore_manager);
    }

    #[abi(embed_v0)]
    impl BookImpl of IBook<ContractState> {
        fn add_book(
            ref self: ContractState,
            book_id: felt252,
            title: felt252,
            author: felt252,
            ISBN: felt252,
            price: u8,
            stock: u8,
        ) {
            let bookstore_manager = self.bookstore_manager.read();
            assert(get_caller_address() == bookstore_manager, 'Only managers can add books!');

            let book = Book { title, author, ISBN, price, stock };

            self.book.write(book_id, book);
            self.book_count.write(stock, book);
            self.emit(BookAdded { title, author, ISBN, price, stock })
        }

        fn update_book(ref self: ContractState, book_id: felt252, new_price: u8) {
            let mut update_book = self.book.read(book_id);
            update_book.price = new_price;
            self.book.write(book_id, update_book);

            self.emit(BookUpdated { title: update_book.title, book_id, price: new_price })
        }

        fn remove_book(ref self: ContractState, book_id: felt252) {
				let book = self.book.read(book_id);
		}

        fn get_book(self: @ContractState, book_id: felt252) -> Book {
            self.book.read(book_id)
        }

        fn get_book_stock(self: @ContractState, book_id: felt252) -> u8 {
            let bookstore_manager = self.bookstore_manager.read();
            assert(get_caller_address() == bookstore_manager, 'Only manager can check stock!');

            let book = self.book.read(book_id);
            return book.stock;
        }
    }
}

