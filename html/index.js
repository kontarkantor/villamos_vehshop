const App = Vue.createApp({
    data() {
      return {
        cars : [
        ],
        currency : "$",
        enableBank : true,
        enableTest : true,
        enableFaction : true,

        search : ""
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
    mounted() {
        var _this = this;
        window.addEventListener('message', function(event) {
            if (event.data.type == "show") {
                document.body.style.display = event.data.enable ? "block" : "none";
            } else if (event.data.type == "config") {
                _this.enableBank = event.data.bank;
                _this.enableTest = event.data.test;
                _this.enableFaction = event.data.faction;
                _this.currency = event.data.currency;
            } 
            else if (event.data.type == "set") {
                _this.cars = event.data.cars;
            }
        });
    }
}).mount('#app');