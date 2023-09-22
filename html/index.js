const App = Vue.createApp({
    data() {
      return {
        cars : [
        ],

        shopdata: {
            money:0,
            bank:0,
            society:0,
            test:true
        },

        name:"Car Dealership",

        locales: {
            nui_currency:"$",
            nui_search:"Search for car name, category or price",
            nui_cash:"Cash",
            nui_bank:"Bank",
            nui_society:"Faction",
            nui_test:"Test"
        },

        search : "",

        opened:false
      }
    },
    computed: {
        filteredList() {
            if (this.search == "") return this.cars;

            const lowsearch = this.search.toLowerCase()

            return this.cars.filter((car) => {
                return car.label.toLowerCase().includes(lowsearch) || car.category.toLowerCase().includes(lowsearch) || String(car.price) == lowsearch;
            });
        }
    },
    methods: {
        haveMoney(price, moneytype) {
            if (!this.shopdata[moneytype]) return "#a83432"
            if (this.shopdata[moneytype] >= price) return "#32a852"
            return "#a83432"
        },
        onMessage(event) {
            if (event.data.type == "show") {
                const appelement = document.getElementById("app");
                if (event.data.enable) {
                    appelement.style.display = "block";
                    appelement.style.animation = "hopin 0.7s";
                    this.opened = true;
                    this.shopdata = event.data.shopdata;
                    this.cars = event.data.cars;
                    this.name = event.data.name;
                } else {
                    appelement.style.animation = "hopout 0.6s";
                    this.opened = false;
                    setTimeout(() => {
                        if (!this.opened) appelement.style.display = "none";
                    }, 500);
                }
            }
        },
        close() {
            fetch(`https://${GetParentResourceName()}/exit`);
        },
        buy(model) {
            fetch(`https://${GetParentResourceName()}/buy`, {
                method: 'POST',
                body: JSON.stringify({
                    model : model
                })
            });
        },
        buybank(model) {
            fetch(`https://${GetParentResourceName()}/buybank`, {
                method: 'POST',
                body: JSON.stringify({
                    model : model
                })
            });
        },
        buyfaction(model) {
            fetch(`https://${GetParentResourceName()}/buyfaction`, {
                method: 'POST',
                body: JSON.stringify({
                    model : model
                })
            });
        },
        test(model) {
            fetch(`https://${GetParentResourceName()}/test`, {
                method: 'POST',
                body: JSON.stringify({
                    model : model
                })
            });
        }
    }, 
    async mounted() {
        window.addEventListener('message', this.onMessage);
        var response = await fetch(`https://${GetParentResourceName()}/locales`);
        var locales = await response.json();
        this.locales = locales;
    }
}).mount('#app');