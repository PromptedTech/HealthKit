import Foundation

/// A single food in the offline library. `kcal`/`protein` are for one `serving`.
/// All values verified against USDA FoodData Central + NIN (National Institute of
/// Nutrition, India) tables. Serving sizes match how people naturally measure the food.
struct FoodItem: Identifiable, Hashable {
    let id: Int
    let name: String
    let serving: String
    let kcal: Double
    let protein: Double
    let category: FoodCategory
}

enum FoodCategory: String, CaseIterable, Identifiable {
    case protein, carbs, dairy, fruit, vegetable, snack, drink, meal, sweet
    var id: String { rawValue }

    var label: String {
        switch self {
        case .vegetable: return "Veggie"
        case .sweet: return "Sweet"
        default: return rawValue.capitalized
        }
    }

    var icon: String {
        switch self {
        case .protein:   return "fish.fill"
        case .carbs:     return "carrot.fill"
        case .dairy:     return "cup.and.saucer.fill"
        case .fruit:     return "leaf.fill"
        case .vegetable: return "leaf.arrow.triangle.circlepath"
        case .snack:     return "takeoutbag.and.cup.and.straw.fill"
        case .drink:     return "waterbottle.fill"
        case .meal:      return "fork.knife"
        case .sweet:     return "birthday.cake.fill"
        }
    }
}

/// Comprehensive offline food library — Indian + Western. Values per USDA & NIN India.
enum FoodLibrary {

    // MARK: - Protein
    static let proteins: [FoodItem] = [
        // Eggs
        FoodItem(id: 1,  name: "Egg (whole)",              serving: "1 large (50g)",  kcal: 78,  protein: 6.3,  category: .protein),
        FoodItem(id: 2,  name: "Egg white",                serving: "1 white (30g)",  kcal: 17,  protein: 3.6,  category: .protein),
        FoodItem(id: 3,  name: "Egg yolk",                 serving: "1 yolk (17g)",   kcal: 55,  protein: 2.7,  category: .protein),
        FoodItem(id: 4,  name: "Boiled egg",               serving: "1 large",        kcal: 78,  protein: 6.3,  category: .protein),
        FoodItem(id: 5,  name: "Omelette (2 eggs)",        serving: "1 serving",      kcal: 190, protein: 13,   category: .protein),
        FoodItem(id: 6,  name: "Scrambled eggs (2 eggs)",  serving: "1 serving",      kcal: 182, protein: 12,   category: .protein),

        // Chicken
        FoodItem(id: 10, name: "Chicken breast (cooked)",  serving: "100 g",          kcal: 165, protein: 31,   category: .protein),
        FoodItem(id: 11, name: "Chicken thigh (cooked)",   serving: "100 g",          kcal: 209, protein: 26,   category: .protein),
        FoodItem(id: 12, name: "Chicken drumstick",        serving: "1 piece (80g)",  kcal: 120, protein: 18,   category: .protein),
        FoodItem(id: 13, name: "Chicken curry",            serving: "1 bowl (200g)",  kcal: 250, protein: 22,   category: .protein),
        FoodItem(id: 14, name: "Butter chicken",           serving: "1 bowl (200g)",  kcal: 320, protein: 22,   category: .protein),
        FoodItem(id: 15, name: "Tandoori chicken",         serving: "2 pieces (120g)",kcal: 185, protein: 28,   category: .protein),
        FoodItem(id: 16, name: "Chicken tikka",            serving: "6 pieces (120g)",kcal: 190, protein: 26,   category: .protein),
        FoodItem(id: 17, name: "Chicken kebab / seekh",    serving: "2 pieces (100g)",kcal: 185, protein: 20,   category: .protein),
        FoodItem(id: 18, name: "Grilled chicken",          serving: "100 g",          kcal: 165, protein: 31,   category: .protein),

        // Mutton / Lamb
        FoodItem(id: 20, name: "Mutton curry",             serving: "1 bowl (200g)",  kcal: 380, protein: 26,   category: .protein),
        FoodItem(id: 21, name: "Mutton keema",             serving: "1 bowl (150g)",  kcal: 310, protein: 22,   category: .protein),
        FoodItem(id: 22, name: "Lamb/goat (cooked)",       serving: "100 g",          kcal: 258, protein: 25,   category: .protein),

        // Fish & Seafood
        FoodItem(id: 25, name: "Rohu / Katla (cooked)",    serving: "100 g",          kcal: 97,  protein: 17,   category: .protein),
        FoodItem(id: 26, name: "Pomfret (cooked)",         serving: "100 g",          kcal: 96,  protein: 19,   category: .protein),
        FoodItem(id: 27, name: "Fish curry",               serving: "1 bowl (200g)",  kcal: 200, protein: 18,   category: .protein),
        FoodItem(id: 28, name: "Sardines (cooked)",        serving: "100 g",          kcal: 208, protein: 25,   category: .protein),
        FoodItem(id: 29, name: "Salmon (cooked)",          serving: "100 g",          kcal: 208, protein: 20,   category: .protein),
        FoodItem(id: 30, name: "Tuna (canned, drained)",   serving: "100 g",          kcal: 116, protein: 26,   category: .protein),
        FoodItem(id: 31, name: "Prawns (cooked)",          serving: "100 g",          kcal: 99,  protein: 24,   category: .protein),
        FoodItem(id: 32, name: "Prawn curry",              serving: "1 bowl (200g)",  kcal: 220, protein: 20,   category: .protein),

        // Paneer & Soy
        FoodItem(id: 35, name: "Paneer (raw)",             serving: "100 g",          kcal: 265, protein: 18,   category: .protein),
        FoodItem(id: 36, name: "Paneer tikka",             serving: "6 pieces (120g)",kcal: 310, protein: 22,   category: .protein),
        FoodItem(id: 37, name: "Palak paneer",             serving: "1 bowl (200g)",  kcal: 260, protein: 14,   category: .meal),
        FoodItem(id: 38, name: "Tofu (firm)",              serving: "100 g",          kcal: 76,  protein: 8,    category: .protein),
        FoodItem(id: 39, name: "Soya chunks (dry)",        serving: "30 g dry",       kcal: 104, protein: 16,   category: .protein),
        FoodItem(id: 40, name: "Soya chunks (cooked)",     serving: "1 cup (150g)",   kcal: 140, protein: 17,   category: .protein),
        FoodItem(id: 41, name: "Soya granules (cooked)",   serving: "1 cup (150g)",   kcal: 135, protein: 16,   category: .protein),

        // Dal / Legumes
        FoodItem(id: 45, name: "Toor dal (cooked)",        serving: "1 cup (180g)",   kcal: 200, protein: 12,   category: .protein),
        FoodItem(id: 46, name: "Moong dal (cooked)",       serving: "1 cup (180g)",   kcal: 147, protein: 14,   category: .protein),
        FoodItem(id: 47, name: "Masoor dal (cooked)",      serving: "1 cup (180g)",   kcal: 230, protein: 18,   category: .protein),
        FoodItem(id: 48, name: "Chana dal (cooked)",       serving: "1 cup (180g)",   kcal: 269, protein: 15,   category: .protein),
        FoodItem(id: 49, name: "Dal makhani",              serving: "1 bowl (200g)",  kcal: 310, protein: 12,   category: .protein),
        FoodItem(id: 50, name: "Dal tadka",                serving: "1 bowl (200g)",  kcal: 190, protein: 10,   category: .protein),
        FoodItem(id: 51, name: "Rajma (cooked)",           serving: "1 cup (180g)",   kcal: 227, protein: 15,   category: .protein),
        FoodItem(id: 52, name: "Chole / Chickpeas (ckd)",  serving: "1 cup (180g)",   kcal: 269, protein: 15,   category: .protein),
        FoodItem(id: 53, name: "Black chana (cooked)",     serving: "1 cup (180g)",   kcal: 210, protein: 14,   category: .protein),
        FoodItem(id: 54, name: "Moong sprouts",            serving: "1 cup (100g)",   kcal: 31,  protein: 3,    category: .protein),
        FoodItem(id: 55, name: "Lentils (whole, cooked)",  serving: "1 cup (180g)",   kcal: 230, protein: 18,   category: .protein),

        // Nuts & Seeds
        FoodItem(id: 58, name: "Almonds",                  serving: "10 nuts (14g)",  kcal: 82,  protein: 3,    category: .protein),
        FoodItem(id: 59, name: "Cashews",                  serving: "10 nuts (14g)",  kcal: 79,  protein: 2.6,  category: .protein),
        FoodItem(id: 60, name: "Walnuts",                  serving: "7 halves (14g)", kcal: 93,  protein: 2.2,  category: .protein),
        FoodItem(id: 61, name: "Peanuts (roasted)",        serving: "30 g",           kcal: 171, protein: 7,    category: .protein),
        FoodItem(id: 62, name: "Peanut butter",            serving: "1 tbsp (16g)",   kcal: 94,  protein: 4,    category: .protein),
        FoodItem(id: 63, name: "Chia seeds",               serving: "1 tbsp (12g)",   kcal: 58,  protein: 2,    category: .protein),
        FoodItem(id: 64, name: "Sunflower seeds",          serving: "30 g",           kcal: 174, protein: 5.8,  category: .protein),
        FoodItem(id: 65, name: "Pumpkin seeds",            serving: "30 g",           kcal: 163, protein: 8,    category: .protein),

        // Supplements
        FoodItem(id: 68, name: "Whey protein (1 scoop)",   serving: "1 scoop (30g)",  kcal: 120, protein: 24,   category: .protein),
        FoodItem(id: 69, name: "Casein protein (1 scoop)", serving: "1 scoop (30g)",  kcal: 120, protein: 24,   category: .protein),
        FoodItem(id: 70, name: "Plant protein (1 scoop)",  serving: "1 scoop (30g)",  kcal: 110, protein: 20,   category: .protein),

        // Western Protein
        FoodItem(id: 73, name: "Turkey breast (cooked)",   serving: "100 g",          kcal: 135, protein: 30,   category: .protein),
        FoodItem(id: 74, name: "Beef (lean, cooked)",      serving: "100 g",          kcal: 250, protein: 26,   category: .protein),
        FoodItem(id: 75, name: "Pork chop (cooked)",       serving: "100 g",          kcal: 231, protein: 25,   category: .protein),
        FoodItem(id: 76, name: "Cottage cheese",           serving: "100 g",          kcal: 98,  protein: 11,   category: .protein),
        FoodItem(id: 77, name: "Greek yogurt (plain)",     serving: "150 g",          kcal: 130, protein: 17,   category: .dairy),
    ]

    // MARK: - Carbs
    static let carbs: [FoodItem] = [
        // Indian Breads
        FoodItem(id: 100, name: "Roti / Chapati",          serving: "1 medium (35g)", kcal: 104, protein: 3,    category: .carbs),
        FoodItem(id: 101, name: "Tandoori roti",           serving: "1 roti (60g)",   kcal: 145, protein: 4.5,  category: .carbs),
        FoodItem(id: 102, name: "Naan (plain)",            serving: "1 naan (90g)",   kcal: 262, protein: 9,    category: .carbs),
        FoodItem(id: 103, name: "Butter naan",             serving: "1 naan (95g)",   kcal: 305, protein: 9,    category: .carbs),
        FoodItem(id: 104, name: "Garlic naan",             serving: "1 naan (95g)",   kcal: 290, protein: 9,    category: .carbs),
        FoodItem(id: 105, name: "Paratha (plain)",         serving: "1 paratha (80g)",kcal: 257, protein: 5.5,  category: .carbs),
        FoodItem(id: 106, name: "Aloo paratha",            serving: "1 paratha (120g)",kcal: 323, protein: 6,   category: .carbs),
        FoodItem(id: 107, name: "Gobhi paratha",           serving: "1 paratha (120g)",kcal: 295, protein: 6,   category: .carbs),
        FoodItem(id: 108, name: "Mooli paratha",           serving: "1 paratha (120g)",kcal: 280, protein: 6,   category: .carbs),
        FoodItem(id: 109, name: "Pyaaz paratha",           serving: "1 paratha (120g)",kcal: 290, protein: 6,   category: .carbs),
        FoodItem(id: 110, name: "Methi paratha",           serving: "1 paratha (80g)",kcal: 230, protein: 6,    category: .carbs),
        FoodItem(id: 111, name: "Puri",                    serving: "2 puris (50g)",  kcal: 195, protein: 3.5,  category: .carbs),
        FoodItem(id: 112, name: "Bhatura",                 serving: "1 piece (90g)",  kcal: 290, protein: 7,    category: .carbs),
        FoodItem(id: 113, name: "Kulcha",                  serving: "1 piece (80g)",  kcal: 240, protein: 7,    category: .carbs),
        FoodItem(id: 114, name: "Missi roti",              serving: "1 roti (50g)",   kcal: 132, protein: 5,    category: .carbs),
        FoodItem(id: 115, name: "Makki roti",              serving: "1 roti (60g)",   kcal: 175, protein: 4,    category: .carbs),
        FoodItem(id: 116, name: "Bajra roti",              serving: "1 roti (50g)",   kcal: 118, protein: 3.7,  category: .carbs),
        FoodItem(id: 117, name: "Jowar roti",              serving: "1 roti (50g)",   kcal: 116, protein: 3.5,  category: .carbs),
        FoodItem(id: 118, name: "Ragi roti",               serving: "1 roti (50g)",   kcal: 108, protein: 3.2,  category: .carbs),

        // Rice
        FoodItem(id: 120, name: "White rice (cooked)",     serving: "1 cup (180g)",   kcal: 234, protein: 4.8,  category: .carbs),
        FoodItem(id: 121, name: "Brown rice (cooked)",     serving: "1 cup (195g)",   kcal: 216, protein: 5,    category: .carbs),
        FoodItem(id: 122, name: "Basmati rice (cooked)",   serving: "1 cup (180g)",   kcal: 230, protein: 4.4,  category: .carbs),
        FoodItem(id: 123, name: "Jeera rice",              serving: "1 plate (200g)", kcal: 280, protein: 5,    category: .carbs),
        FoodItem(id: 124, name: "Dal rice",                serving: "1 plate (350g)", kcal: 400, protein: 12,   category: .carbs),

        // South Indian Breakfast
        FoodItem(id: 128, name: "Idli",                    serving: "2 pieces (100g)",kcal: 116, protein: 4,    category: .carbs),
        FoodItem(id: 129, name: "Dosa (plain)",            serving: "1 dosa (80g)",   kcal: 168, protein: 4,    category: .carbs),
        FoodItem(id: 130, name: "Uttapam",                 serving: "1 piece (100g)", kcal: 170, protein: 4.5,  category: .carbs),
        FoodItem(id: 131, name: "Medu vada",               serving: "2 pieces (80g)", kcal: 210, protein: 6,    category: .carbs),
        FoodItem(id: 132, name: "Appam",                   serving: "2 pieces (80g)", kcal: 160, protein: 3,    category: .carbs),
        FoodItem(id: 133, name: "Rava dosa",               serving: "1 dosa (80g)",   kcal: 150, protein: 4,    category: .carbs),
        FoodItem(id: 134, name: "Pesarattu",               serving: "2 pieces (100g)",kcal: 140, protein: 7,    category: .carbs),
        FoodItem(id: 135, name: "Puttu",                   serving: "1 cup (100g)",   kcal: 177, protein: 3.5,  category: .carbs),
        FoodItem(id: 136, name: "Idiyappam",               serving: "2 pieces (100g)",kcal: 142, protein: 2.5,  category: .carbs),

        // North Indian Breakfast
        FoodItem(id: 138, name: "Poha",                    serving: "1 bowl (180g)",  kcal: 250, protein: 5,    category: .carbs),
        FoodItem(id: 139, name: "Upma",                    serving: "1 bowl (200g)",  kcal: 250, protein: 6,    category: .carbs),
        FoodItem(id: 140, name: "Rava upma",               serving: "1 bowl (200g)",  kcal: 260, protein: 6,    category: .carbs),
        FoodItem(id: 141, name: "Besan chilla",            serving: "2 pieces (150g)",kcal: 210, protein: 9,    category: .carbs),
        FoodItem(id: 142, name: "Daliya / Broken wheat",   serving: "1 bowl (200g)",  kcal: 220, protein: 7,    category: .carbs),
        FoodItem(id: 143, name: "Sattu drink",             serving: "1 glass (200ml)",kcal: 150, protein: 8,    category: .carbs),

        // Cereals & Oats
        FoodItem(id: 146, name: "Oats (raw)",              serving: "40 g dry",       kcal: 150, protein: 5.4,  category: .carbs),
        FoodItem(id: 147, name: "Oatmeal (cooked)",        serving: "1 bowl (250g)",  kcal: 166, protein: 6,    category: .carbs),
        FoodItem(id: 148, name: "Corn flakes",             serving: "30 g + 100ml milk",kcal: 170, protein: 5,  category: .carbs),
        FoodItem(id: 149, name: "Muesli",                  serving: "40 g",           kcal: 150, protein: 4,    category: .carbs),
        FoodItem(id: 150, name: "Granola",                 serving: "40 g",           kcal: 186, protein: 4,    category: .carbs),

        // Western Carbs
        FoodItem(id: 153, name: "Bread (white)",           serving: "1 slice (30g)",  kcal: 80,  protein: 2.7,  category: .carbs),
        FoodItem(id: 154, name: "Bread (whole wheat)",     serving: "1 slice (30g)",  kcal: 69,  protein: 3.6,  category: .carbs),
        FoodItem(id: 155, name: "Pasta (cooked)",          serving: "1 cup (140g)",   kcal: 220, protein: 8,    category: .carbs),
        FoodItem(id: 156, name: "Spaghetti (cooked)",      serving: "1 cup (140g)",   kcal: 220, protein: 8,    category: .carbs),
        FoodItem(id: 157, name: "Boiled potato",           serving: "1 medium (150g)",kcal: 130, protein: 3,    category: .carbs),
        FoodItem(id: 158, name: "Sweet potato (boiled)",   serving: "1 medium (130g)",kcal: 112, protein: 2,    category: .carbs),
        FoodItem(id: 159, name: "Quinoa (cooked)",         serving: "1 cup (185g)",   kcal: 222, protein: 8,    category: .carbs),
        FoodItem(id: 160, name: "Khichdi",                 serving: "1 bowl (250g)",  kcal: 300, protein: 9,    category: .carbs),
        FoodItem(id: 161, name: "Curd rice",               serving: "1 bowl (200g)",  kcal: 260, protein: 7,    category: .carbs),
        FoodItem(id: 162, name: "Pongal (sweet)",          serving: "1 bowl (200g)",  kcal: 320, protein: 5,    category: .carbs),
        FoodItem(id: 163, name: "Ven pongal",              serving: "1 bowl (200g)",  kcal: 280, protein: 7,    category: .carbs),
        FoodItem(id: 164, name: "Sambar",                  serving: "1 bowl (200ml)", kcal: 80,  protein: 5,    category: .carbs),
        FoodItem(id: 165, name: "Rasam",                   serving: "1 bowl (200ml)", kcal: 40,  protein: 2,    category: .carbs),
    ]

    // MARK: - Dairy
    static let dairy: [FoodItem] = [
        FoodItem(id: 200, name: "Milk (full fat)",         serving: "1 glass (250ml)",kcal: 150, protein: 8,    category: .dairy),
        FoodItem(id: 201, name: "Milk (toned / 2%)",       serving: "1 glass (250ml)",kcal: 120, protein: 8,    category: .dairy),
        FoodItem(id: 202, name: "Skim milk",               serving: "1 glass (250ml)",kcal: 86,  protein: 8.4,  category: .dairy),
        FoodItem(id: 203, name: "Curd / Dahi (full fat)",  serving: "1 cup (200g)",   kcal: 120, protein: 7,    category: .dairy),
        FoodItem(id: 204, name: "Curd (low fat)",          serving: "1 cup (200g)",   kcal: 84,  protein: 8,    category: .dairy),
        FoodItem(id: 205, name: "Greek yogurt",            serving: "150 g",          kcal: 130, protein: 17,   category: .dairy),
        FoodItem(id: 206, name: "Chaas / Buttermilk",      serving: "1 glass (250ml)",kcal: 40,  protein: 3,    category: .dairy),
        FoodItem(id: 207, name: "Lassi (sweet)",           serving: "1 glass (250ml)",kcal: 200, protein: 6,    category: .dairy),
        FoodItem(id: 208, name: "Lassi (salted)",          serving: "1 glass (250ml)",kcal: 100, protein: 5,    category: .dairy),
        FoodItem(id: 209, name: "Shrikhand",               serving: "100 g",          kcal: 195, protein: 6,    category: .dairy),
        FoodItem(id: 210, name: "Ghee",                    serving: "1 tsp (5g)",     kcal: 45,  protein: 0,    category: .dairy),
        FoodItem(id: 211, name: "Butter",                  serving: "1 tsp (5g)",     kcal: 36,  protein: 0,    category: .dairy),
        FoodItem(id: 212, name: "Paneer (raw)",            serving: "100 g",          kcal: 265, protein: 18,   category: .dairy),
        FoodItem(id: 213, name: "Cheese (processed)",      serving: "1 slice (25g)",  kcal: 70,  protein: 4,    category: .dairy),
        FoodItem(id: 214, name: "Mozzarella cheese",       serving: "30 g",           kcal: 90,  protein: 6.3,  category: .dairy),
        FoodItem(id: 215, name: "Khoa / Mawa",             serving: "50 g",           kcal: 185, protein: 7,    category: .dairy),
        FoodItem(id: 216, name: "Condensed milk",          serving: "2 tbsp (30g)",   kcal: 98,  protein: 2.5,  category: .dairy),
        FoodItem(id: 217, name: "Cream (fresh)",           serving: "2 tbsp (30g)",   kcal: 103, protein: 0.7,  category: .dairy),
        FoodItem(id: 218, name: "Ice cream (vanilla)",     serving: "1 scoop (70g)",  kcal: 137, protein: 2.3,  category: .dairy),
        FoodItem(id: 219, name: "Raita (plain)",           serving: "1 bowl (150g)",  kcal: 75,  protein: 4.5,  category: .dairy),
    ]

    // MARK: - Fruits
    static let fruitsAndMangoes: [FoodItem] = [
        // Common fruits
        FoodItem(id: 250, name: "Banana",                  serving: "1 medium (120g)",kcal: 105, protein: 1.3,  category: .fruit),
        FoodItem(id: 251, name: "Apple",                   serving: "1 medium (182g)",kcal: 95,  protein: 0.5,  category: .fruit),
        FoodItem(id: 252, name: "Orange",                  serving: "1 medium (131g)",kcal: 62,  protein: 1.2,  category: .fruit),
        FoodItem(id: 253, name: "Pomegranate",             serving: "½ fruit (120g)", kcal: 83,  protein: 1.7,  category: .fruit),
        FoodItem(id: 254, name: "Papaya",                  serving: "1 cup (140g)",   kcal: 55,  protein: 0.9,  category: .fruit),
        FoodItem(id: 255, name: "Watermelon",              serving: "1 cup (152g)",   kcal: 46,  protein: 0.9,  category: .fruit),
        FoodItem(id: 256, name: "Grapes",                  serving: "1 cup (151g)",   kcal: 104, protein: 1.1,  category: .fruit),
        FoodItem(id: 257, name: "Guava",                   serving: "1 medium (120g)",kcal: 68,  protein: 2.6,  category: .fruit),
        FoodItem(id: 258, name: "Pineapple",               serving: "1 cup (165g)",   kcal: 82,  protein: 0.9,  category: .fruit),
        FoodItem(id: 259, name: "Chikoo / Sapota",         serving: "1 medium (100g)",kcal: 83,  protein: 0.4,  category: .fruit),
        FoodItem(id: 260, name: "Jamun / Black plum",      serving: "1 cup (100g)",   kcal: 62,  protein: 0.7,  category: .fruit),
        FoodItem(id: 261, name: "Lychee",                  serving: "10 pieces (100g)",kcal: 66, protein: 0.8,  category: .fruit),
        FoodItem(id: 262, name: "Custard apple (Sitafal)", serving: "1 medium (100g)",kcal: 94,  protein: 1.7,  category: .fruit),
        FoodItem(id: 263, name: "Amla / Indian gooseberry",serving: "5 pieces (50g)", kcal: 22,  protein: 0.5,  category: .fruit),
        FoodItem(id: 264, name: "Dates (Khajoor)",         serving: "3 pieces (30g)", kcal: 80,  protein: 0.6,  category: .fruit),
        FoodItem(id: 265, name: "Coconut (fresh)",         serving: "30 g",           kcal: 106, protein: 1,    category: .fruit),
        FoodItem(id: 266, name: "Strawberries",            serving: "1 cup (152g)",   kcal: 49,  protein: 1,    category: .fruit),
        FoodItem(id: 267, name: "Blueberries",             serving: "1 cup (148g)",   kcal: 84,  protein: 1.1,  category: .fruit),
        FoodItem(id: 268, name: "Kiwi",                    serving: "1 medium (76g)", kcal: 46,  protein: 0.9,  category: .fruit),
        FoodItem(id: 269, name: "Pear",                    serving: "1 medium (178g)",kcal: 101, protein: 0.6,  category: .fruit),
        FoodItem(id: 270, name: "Peach",                   serving: "1 medium (150g)",kcal: 58,  protein: 1.4,  category: .fruit),
        FoodItem(id: 271, name: "Plum",                    serving: "2 medium (130g)",kcal: 61,  protein: 0.9,  category: .fruit),
        FoodItem(id: 272, name: "Avocado",                 serving: "½ fruit (68g)",  kcal: 114, protein: 1.3,  category: .fruit),
        FoodItem(id: 273, name: "Fig / Anjeer",            serving: "2 medium (100g)",kcal: 74,  protein: 0.8,  category: .fruit),

        // ── Indian Mango Varieties ──
        // Per 100g flesh. Alphonso is richer/sweeter, Totapuri less sweet.
        FoodItem(id: 280, name: "Mango — Alphonso (Hapus)",   serving: "100 g",   kcal: 73, protein: 0.8, category: .fruit),
        FoodItem(id: 281, name: "Mango — Kesar (Gir Kesar)",  serving: "100 g",   kcal: 70, protein: 0.8, category: .fruit),
        FoodItem(id: 282, name: "Mango — Dasheri",            serving: "100 g",   kcal: 69, protein: 0.9, category: .fruit),
        FoodItem(id: 283, name: "Mango — Langra",             serving: "100 g",   kcal: 68, protein: 0.8, category: .fruit),
        FoodItem(id: 284, name: "Mango — Banganapalli/Benishan",serving:"100 g",  kcal: 65, protein: 0.8, category: .fruit),
        FoodItem(id: 285, name: "Mango — Totapuri",           serving: "100 g",   kcal: 56, protein: 0.7, category: .fruit),
        FoodItem(id: 286, name: "Mango — Safeda/Bombay Green",serving: "100 g",   kcal: 66, protein: 0.8, category: .fruit),
        FoodItem(id: 287, name: "Mango — Neelam",             serving: "100 g",   kcal: 62, protein: 0.8, category: .fruit),
        FoodItem(id: 288, name: "Mango — Himsagar",           serving: "100 g",   kcal: 71, protein: 0.8, category: .fruit),
        FoodItem(id: 289, name: "Mango — Chaunsa",            serving: "100 g",   kcal: 70, protein: 0.8, category: .fruit),
        FoodItem(id: 290, name: "Mango — Badami",             serving: "100 g",   kcal: 68, protein: 0.8, category: .fruit),
        FoodItem(id: 291, name: "Mango — Raspuri",            serving: "100 g",   kcal: 65, protein: 0.8, category: .fruit),
        FoodItem(id: 292, name: "Mango — Mallika",            serving: "100 g",   kcal: 69, protein: 0.9, category: .fruit),
        FoodItem(id: 293, name: "Mango — Amrapali",           serving: "100 g",   kcal: 67, protein: 0.9, category: .fruit),
        FoodItem(id: 294, name: "Mango — Malgova/Malgoba",    serving: "100 g",   kcal: 72, protein: 0.8, category: .fruit),
        FoodItem(id: 295, name: "Mango — Mankurad (Goa)",     serving: "100 g",   kcal: 71, protein: 0.8, category: .fruit),
        FoodItem(id: 296, name: "Mango — Fazli",              serving: "100 g",   kcal: 66, protein: 0.8, category: .fruit),
        FoodItem(id: 297, name: "Mango — Sindhuri",           serving: "100 g",   kcal: 67, protein: 0.8, category: .fruit),
        FoodItem(id: 298, name: "Mango — Imam Pasand/Himayat",serving: "100 g",   kcal: 72, protein: 0.8, category: .fruit),
        FoodItem(id: 299, name: "Mango — Gulabkhas",          serving: "100 g",   kcal: 70, protein: 0.8, category: .fruit),
        FoodItem(id: 300, name: "Mango — Rataul",             serving: "100 g",   kcal: 69, protein: 0.8, category: .fruit),
        FoodItem(id: 301, name: "Mango — Suvarnarekha",       serving: "100 g",   kcal: 67, protein: 0.8, category: .fruit),
        FoodItem(id: 302, name: "Mango — Namdhari",           serving: "100 g",   kcal: 68, protein: 0.8, category: .fruit),
        FoodItem(id: 303, name: "Mango — Sundari",            serving: "100 g",   kcal: 66, protein: 0.8, category: .fruit),
        FoodItem(id: 304, name: "Mango (generic, 1 slice)",   serving: "1 slice (80g)",kcal: 51, protein: 0.6,category: .fruit),
        FoodItem(id: 305, name: "Mango (1 cup diced)",        serving: "1 cup (165g)",kcal: 107, protein: 1.4,category: .fruit),
        FoodItem(id: 306, name: "Aam panna (raw mango drink)",serving: "1 glass (200ml)",kcal: 80, protein: 0.5,category: .drink),
    ]

    // MARK: - Vegetables (cooked, Indian style unless noted)
    static let vegetables: [FoodItem] = [
        FoodItem(id: 330, name: "Aloo sabzi",              serving: "1 bowl (150g)",  kcal: 180, protein: 3,    category: .vegetable),
        FoodItem(id: 331, name: "Aloo gobi",               serving: "1 bowl (150g)",  kcal: 170, protein: 4,    category: .vegetable),
        FoodItem(id: 332, name: "Bhindi masala",           serving: "1 bowl (150g)",  kcal: 140, protein: 3,    category: .vegetable),
        FoodItem(id: 333, name: "Baingan bharta",          serving: "1 bowl (150g)",  kcal: 145, protein: 3,    category: .vegetable),
        FoodItem(id: 334, name: "Palak sabzi",             serving: "1 bowl (150g)",  kcal: 90,  protein: 5,    category: .vegetable),
        FoodItem(id: 335, name: "Methi sabzi",             serving: "1 bowl (150g)",  kcal: 100, protein: 4,    category: .vegetable),
        FoodItem(id: 336, name: "Gajar halwa (carrot)",    serving: "1 bowl (100g)",  kcal: 200, protein: 3,    category: .sweet),
        FoodItem(id: 337, name: "Mixed vegetable curry",   serving: "1 bowl (200g)",  kcal: 160, protein: 4,    category: .vegetable),
        FoodItem(id: 338, name: "Mutter paneer",           serving: "1 bowl (200g)",  kcal: 310, protein: 14,   category: .meal),
        FoodItem(id: 339, name: "Sarson da saag",          serving: "1 bowl (200g)",  kcal: 120, protein: 6,    category: .vegetable),
        FoodItem(id: 340, name: "Kadai paneer",            serving: "1 bowl (200g)",  kcal: 310, protein: 14,   category: .meal),
        FoodItem(id: 341, name: "Shahi paneer",            serving: "1 bowl (200g)",  kcal: 340, protein: 14,   category: .meal),
        FoodItem(id: 342, name: "Veg curry (misc)",        serving: "1 bowl (200g)",  kcal: 150, protein: 4,    category: .vegetable),
        FoodItem(id: 343, name: "Broccoli (steamed)",      serving: "1 cup (91g)",    kcal: 31,  protein: 2.6,  category: .vegetable),
        FoodItem(id: 344, name: "Spinach (raw)",           serving: "1 cup (30g)",    kcal: 7,   protein: 0.9,  category: .vegetable),
        FoodItem(id: 345, name: "Cauliflower (cooked)",    serving: "1 cup (120g)",   kcal: 29,  protein: 2.3,  category: .vegetable),
        FoodItem(id: 346, name: "Carrot (raw)",            serving: "1 medium (60g)", kcal: 25,  protein: 0.6,  category: .vegetable),
        FoodItem(id: 347, name: "Cucumber (raw)",          serving: "1 medium (100g)",kcal: 16,  protein: 0.7,  category: .vegetable),
        FoodItem(id: 348, name: "Tomato (raw)",            serving: "1 medium (123g)",kcal: 22,  protein: 1.1,  category: .vegetable),
        FoodItem(id: 349, name: "Onion (raw)",             serving: "1 medium (110g)",kcal: 44,  protein: 1.2,  category: .vegetable),
    ]

    // MARK: - Snacks
    static let snacks: [FoodItem] = [
        // Indian snacks
        FoodItem(id: 370, name: "Samosa (small)",          serving: "1 piece (60g)",  kcal: 180, protein: 3,    category: .snack),
        FoodItem(id: 371, name: "Pakora / Bhajiya",        serving: "4 pieces (80g)", kcal: 200, protein: 4,    category: .snack),
        FoodItem(id: 372, name: "Vada pav",                serving: "1 piece (120g)", kcal: 290, protein: 7,    category: .snack),
        FoodItem(id: 373, name: "Dhokla",                  serving: "4 pieces (100g)",kcal: 130, protein: 5,    category: .snack),
        FoodItem(id: 374, name: "Khandvi",                 serving: "4 pieces (80g)", kcal: 120, protein: 5,    category: .snack),
        FoodItem(id: 375, name: "Pani puri / Golgappa",    serving: "6 pieces",       kcal: 180, protein: 3,    category: .snack),
        FoodItem(id: 376, name: "Bhel puri",               serving: "1 bowl (100g)",  kcal: 155, protein: 4,    category: .snack),
        FoodItem(id: 377, name: "Pav bhaji",               serving: "1 plate",        kcal: 420, protein: 9,    category: .meal),
        FoodItem(id: 378, name: "Kachori",                 serving: "1 piece (60g)",  kcal: 220, protein: 5,    category: .snack),
        FoodItem(id: 379, name: "Dhokla (steamed)",        serving: "4 pieces (100g)",kcal: 130, protein: 5,    category: .snack),
        FoodItem(id: 380, name: "Makhana (roasted)",       serving: "30 g",           kcal: 106, protein: 3.7,  category: .snack),
        FoodItem(id: 381, name: "Roasted chana",           serving: "30 g",           kcal: 120, protein: 6.5,  category: .snack),
        FoodItem(id: 382, name: "Chakli / Murukku",        serving: "3 pieces (30g)", kcal: 150, protein: 2,    category: .snack),
        FoodItem(id: 383, name: "Popcorn (plain)",         serving: "1 cup (8g)",     kcal: 31,  protein: 1,    category: .snack),
        FoodItem(id: 384, name: "Chips (potato)",          serving: "1 pack (26g)",   kcal: 133, protein: 1.6,  category: .snack),
        FoodItem(id: 385, name: "Mixed nuts",              serving: "30 g",           kcal: 180, protein: 5,    category: .snack),
        FoodItem(id: 386, name: "Protein bar",             serving: "1 bar (60g)",    kcal: 200, protein: 20,   category: .snack),
        FoodItem(id: 387, name: "Dark chocolate (70%+)",   serving: "2 squares (20g)",kcal: 110, protein: 1.5,  category: .snack),
        FoodItem(id: 388, name: "Biscuit (Marie)",         serving: "3 pieces (21g)", kcal: 87,  protein: 1.6,  category: .snack),
        FoodItem(id: 389, name: "Biscuit (digestive)",     serving: "2 pieces (30g)", kcal: 140, protein: 2,    category: .snack),
        FoodItem(id: 390, name: "Murmure / Puffed rice",   serving: "1 cup (15g)",    kcal: 56,  protein: 1,    category: .snack),
        FoodItem(id: 391, name: "Sev (plain)",             serving: "30 g",           kcal: 145, protein: 3.5,  category: .snack),
        FoodItem(id: 392, name: "Boondi (plain)",          serving: "30 g",           kcal: 130, protein: 3,    category: .snack),
        FoodItem(id: 393, name: "Nachos with salsa",       serving: "1 small plate",  kcal: 200, protein: 3,    category: .snack),
        FoodItem(id: 394, name: "Hummus",                  serving: "2 tbsp (30g)",   kcal: 70,  protein: 2,    category: .snack),
        FoodItem(id: 395, name: "Pita bread",              serving: "1 piece (60g)",  kcal: 165, protein: 5.5,  category: .snack),
    ]

    // MARK: - Drinks
    static let drinks: [FoodItem] = [
        FoodItem(id: 420, name: "Tea with milk & sugar",   serving: "1 cup (200ml)",  kcal: 70,  protein: 1.5,  category: .drink),
        FoodItem(id: 421, name: "Tea (black, no sugar)",   serving: "1 cup (200ml)",  kcal: 5,   protein: 0,    category: .drink),
        FoodItem(id: 422, name: "Coffee (latte, milk)",    serving: "1 cup (240ml)",  kcal: 120, protein: 6,    category: .drink),
        FoodItem(id: 423, name: "Black coffee",            serving: "1 cup (240ml)",  kcal: 5,   protein: 0,    category: .drink),
        FoodItem(id: 424, name: "Green tea",               serving: "1 cup (240ml)",  kcal: 2,   protein: 0,    category: .drink),
        FoodItem(id: 425, name: "Protein shake (milk)",    serving: "1 glass (300ml)",kcal: 290, protein: 32,   category: .drink),
        FoodItem(id: 426, name: "Orange juice (fresh)",    serving: "1 glass (240ml)",kcal: 112, protein: 1.7,  category: .drink),
        FoodItem(id: 427, name: "Coconut water",           serving: "1 glass (240ml)",kcal: 46,  protein: 1.7,  category: .drink),
        FoodItem(id: 428, name: "Sugarcane juice",         serving: "1 glass (240ml)",kcal: 166, protein: 0.2,  category: .drink),
        FoodItem(id: 429, name: "Nimbu pani / Lemonade",   serving: "1 glass (240ml)",kcal: 60,  protein: 0.2,  category: .drink),
        FoodItem(id: 430, name: "Soft drink (cola)",       serving: "1 can (330ml)",  kcal: 140, protein: 0,    category: .drink),
        FoodItem(id: 431, name: "Mango shake",             serving: "1 glass (300ml)",kcal: 260, protein: 6,    category: .drink),
        FoodItem(id: 432, name: "Banana shake",            serving: "1 glass (300ml)",kcal: 250, protein: 7,    category: .drink),
        FoodItem(id: 433, name: "Turmeric milk / Haldi doodh", serving: "1 cup (250ml)",kcal: 160, protein: 8,  category: .drink),
        FoodItem(id: 434, name: "Jal jeera",               serving: "1 glass (200ml)",kcal: 25,  protein: 0.5,  category: .drink),
        FoodItem(id: 435, name: "Sports drink (Gatorade)", serving: "1 bottle (500ml)",kcal: 130, protein: 0,   category: .drink),
        FoodItem(id: 436, name: "Beer",                    serving: "1 can (330ml)",  kcal: 154, protein: 1.6,  category: .drink),
        FoodItem(id: 437, name: "Almond milk (unsweetened)",serving:"1 cup (240ml)",  kcal: 39,  protein: 1.5,  category: .drink),
        FoodItem(id: 438, name: "Soy milk",                serving: "1 cup (240ml)",  kcal: 105, protein: 6,    category: .drink),
        FoodItem(id: 439, name: "Thandai",                 serving: "1 glass (250ml)",kcal: 200, protein: 5,    category: .drink),
    ]

    // MARK: - Complete Meals
    static let meals: [FoodItem] = [
        // Indian
        FoodItem(id: 460, name: "Chicken biryani",         serving: "1 plate (300g)", kcal: 450, protein: 24,   category: .meal),
        FoodItem(id: 461, name: "Mutton biryani",          serving: "1 plate (300g)", kcal: 510, protein: 26,   category: .meal),
        FoodItem(id: 462, name: "Veg biryani",             serving: "1 plate (300g)", kcal: 370, protein: 9,    category: .meal),
        FoodItem(id: 463, name: "Rajma chawal",            serving: "1 plate (350g)", kcal: 430, protein: 16,   category: .meal),
        FoodItem(id: 464, name: "Dal chawal",              serving: "1 plate (350g)", kcal: 400, protein: 13,   category: .meal),
        FoodItem(id: 465, name: "Chole bhature",           serving: "1 plate (300g)", kcal: 650, protein: 17,   category: .meal),
        FoodItem(id: 466, name: "Masala dosa (with sambar)",serving: "1 dosa",        kcal: 340, protein: 7,    category: .meal),
        FoodItem(id: 467, name: "Idli (2) + sambar",       serving: "1 plate",        kcal: 190, protein: 8,    category: .meal),
        FoodItem(id: 468, name: "Thali (veg)",             serving: "1 plate",        kcal: 600, protein: 18,   category: .meal),
        FoodItem(id: 469, name: "Thali (non-veg, chicken)",serving: "1 plate",        kcal: 750, protein: 35,   category: .meal),
        FoodItem(id: 470, name: "Egg rice / egg fried rice",serving: "1 plate (200g)",kcal: 310, protein: 13,   category: .meal),
        FoodItem(id: 471, name: "Chicken fried rice",      serving: "1 plate (200g)", kcal: 360, protein: 18,   category: .meal),
        FoodItem(id: 472, name: "Hakka noodles (veg)",     serving: "1 plate (200g)", kcal: 320, protein: 7,    category: .meal),
        FoodItem(id: 473, name: "Chow mein (chicken)",     serving: "1 plate (200g)", kcal: 380, protein: 18,   category: .meal),
        FoodItem(id: 474, name: "Maggi noodles (cooked)",  serving: "1 pack",         kcal: 350, protein: 8,    category: .meal),
        FoodItem(id: 475, name: "Egg curry",               serving: "1 bowl (200g)",  kcal: 250, protein: 14,   category: .meal),
        FoodItem(id: 476, name: "Dal makhani",             serving: "1 bowl (200g)",  kcal: 310, protein: 12,   category: .meal),
        FoodItem(id: 477, name: "Paneer butter masala",    serving: "1 bowl (200g)",  kcal: 350, protein: 14,   category: .meal),
        FoodItem(id: 478, name: "Bisi bele bath",          serving: "1 bowl (250g)",  kcal: 350, protein: 10,   category: .meal),

        // Western / Fast food
        FoodItem(id: 480, name: "Chicken sandwich",        serving: "1 sandwich",     kcal: 350, protein: 22,   category: .meal),
        FoodItem(id: 481, name: "Veg sandwich",            serving: "1 sandwich",     kcal: 250, protein: 8,    category: .meal),
        FoodItem(id: 482, name: "Chicken burger",          serving: "1 burger",       kcal: 490, protein: 28,   category: .meal),
        FoodItem(id: 483, name: "Veg burger",              serving: "1 burger",       kcal: 380, protein: 12,   category: .meal),
        FoodItem(id: 484, name: "Pizza (cheese, 1 slice)", serving: "1 slice (107g)", kcal: 272, protein: 12,   category: .meal),
        FoodItem(id: 485, name: "Pizza (chicken, 1 slice)",serving: "1 slice (107g)", kcal: 290, protein: 15,   category: .meal),
        FoodItem(id: 486, name: "Pasta with sauce",        serving: "1 plate (250g)", kcal: 330, protein: 11,   category: .meal),
        FoodItem(id: 487, name: "Grilled chicken salad",   serving: "1 bowl (250g)",  kcal: 200, protein: 22,   category: .meal),
        FoodItem(id: 488, name: "Caesar salad (no croutons)", serving: "1 bowl (200g)",kcal: 170, protein: 10,  category: .meal),
        FoodItem(id: 489, name: "Omelette + 2 toast",      serving: "1 serving",      kcal: 340, protein: 18,   category: .meal),
        FoodItem(id: 490, name: "Poha + curd",             serving: "1 serving",      kcal: 340, protein: 11,   category: .meal),
        FoodItem(id: 491, name: "Oats + milk + banana",    serving: "1 bowl",         kcal: 320, protein: 12,   category: .meal),
    ]

    // MARK: - Sweets
    static let sweets: [FoodItem] = [
        FoodItem(id: 510, name: "Gulab jamun",             serving: "2 pieces (80g)", kcal: 250, protein: 3.5,  category: .sweet),
        FoodItem(id: 511, name: "Rasgulla",                serving: "2 pieces (100g)",kcal: 186, protein: 4,    category: .sweet),
        FoodItem(id: 512, name: "Jalebi",                  serving: "2 pieces (60g)", kcal: 150, protein: 1.5,  category: .sweet),
        FoodItem(id: 513, name: "Ladoo (besan)",           serving: "1 piece (50g)",  kcal: 215, protein: 3.5,  category: .sweet),
        FoodItem(id: 514, name: "Ladoo (motichoor)",       serving: "1 piece (50g)",  kcal: 195, protein: 3,    category: .sweet),
        FoodItem(id: 515, name: "Barfi (milk)",            serving: "1 piece (40g)",  kcal: 150, protein: 4,    category: .sweet),
        FoodItem(id: 516, name: "Barfi (kaju)",            serving: "1 piece (30g)",  kcal: 130, protein: 2.5,  category: .sweet),
        FoodItem(id: 517, name: "Halwa (suji/rava)",       serving: "1 bowl (100g)",  kcal: 250, protein: 4,    category: .sweet),
        FoodItem(id: 518, name: "Halwa (gajar/carrot)",    serving: "1 bowl (100g)",  kcal: 200, protein: 3,    category: .sweet),
        FoodItem(id: 519, name: "Kheer (rice pudding)",    serving: "1 bowl (150g)",  kcal: 220, protein: 5,    category: .sweet),
        FoodItem(id: 520, name: "Rasmalai",                serving: "2 pieces (100g)",kcal: 180, protein: 6,    category: .sweet),
        FoodItem(id: 521, name: "Kulfi",                   serving: "1 stick (80g)",  kcal: 180, protein: 5,    category: .sweet),
        FoodItem(id: 522, name: "Rabri",                   serving: "1 bowl (100g)",  kcal: 200, protein: 6,    category: .sweet),
        FoodItem(id: 523, name: "Peda",                    serving: "2 pieces (40g)", kcal: 160, protein: 4,    category: .sweet),
        FoodItem(id: 524, name: "Chikki (peanut)",         serving: "1 piece (30g)",  kcal: 140, protein: 3.5,  category: .sweet),
        FoodItem(id: 525, name: "Brownie",                 serving: "1 piece (60g)",  kcal: 243, protein: 3,    category: .sweet),
        FoodItem(id: 526, name: "Cake (plain sponge)",     serving: "1 slice (80g)",  kcal: 270, protein: 4,    category: .sweet),
        FoodItem(id: 527, name: "Ice cream cone",          serving: "1 cone (120g)",  kcal: 230, protein: 4,    category: .sweet),
        FoodItem(id: 528, name: "Mango ice cream",         serving: "1 scoop (100g)", kcal: 180, protein: 2.5,  category: .sweet),
        FoodItem(id: 529, name: "Payasam / Kheer",         serving: "1 bowl (150g)",  kcal: 230, protein: 5,    category: .sweet),
    ]

    // MARK: - Combined list & search

    static let all: [FoodItem] =
        proteins + carbs + dairy + fruitsAndMangoes +
        vegetables + snacks + drinks + meals + sweets

    /// Case- and diacritic-insensitive name search. Empty query returns full list.
    static func search(_ query: String) -> [FoodItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return all }
        return all.filter {
            $0.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    static func items(in category: FoodCategory) -> [FoodItem] {
        all.filter { $0.category == category }
    }
}
