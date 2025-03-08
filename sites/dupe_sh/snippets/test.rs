pub mod search {
    pub fn binary_search<T: Ord>(slice: &[T], target: T) -> Option<usize> {
        let mut left = 0;
        let mut right = slice.len();

        while left < right {
            let mid = left + (right - left) / 2;
            if slice[mid] == target {
                return Some(mid);
            } else if slice[mid] < target {
                left = mid + 1;
            } else {
                right = mid;
            }
        }
        None
    }
}
